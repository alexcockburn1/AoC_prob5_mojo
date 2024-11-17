from collections import List
from algorithm import parallelize
import math

alias type = DType.uint32
alias simdwith = simdwidthof[type]()

# This is a test


def parse_list_of_ints(in_string: String) -> List[Int]:
    str_list = in_string.split(" ")
    result = List[Int]()
    for i in range(len(str_list)):
        result.append(atol(str_list[i]))
    return result


@value
struct ShiftInterval:
    var source_start: Int
    var source_end: Int
    var shift: Int

    fn __init__(inout self, destination_start: Int, source_start: Int, source_end: Int):
        self.source_start = source_start
        self.source_end = source_end
        self.shift = destination_start - source_start
    
    fn __str__(self) -> String:
        return "ShiftInterval, shift=" + str(self.shift) + ", source_start=" + str(self.source_start) + ", source_end=" + str(self.source_end)


@value
struct Mapping:
    var intervals: List[ShiftInterval]

    fn __init__(inout self):
        self.intervals = List[ShiftInterval]()
    
    fn apply_mapping(self, number: Int) -> Int:
        for i in range(len(self.intervals)):
            var interval = self.intervals[i]
            if interval.source_start <= number < interval.source_end:
                return number + interval.shift
        return number


@value
struct MappingVectorizable:
    var source_starts: DTypePointer[type]
    var source_ends: DTypePointer[type]
    var shifts: DTypePointer[type]
    var mapping_size: Int

    fn __init__(inout self, mapping: Mapping):
        self.mapping_size = len(mapping.intervals)
        self.source_starts = DTypePointer[type].alloc(self.mapping_size)
        self.source_ends = DTypePointer[type].alloc(self.mapping_size)
        self.shifts = DTypePointer[type].alloc(self.mapping_size)
        for i in range(self.mapping_size):
            self.source_starts[i] = mapping.intervals[i].source_start
            self.source_ends[i] = mapping.intervals[i].source_end
            self.shifts[i] = mapping.intervals[i].shift

    fn apply_mapping(self, number: Int) -> Int:
        
        for i in range(self.mapping_size//simdwith):
            var number_simd = SIMD[type, simdwith](number)
            var source_starts_batch = self.source_starts.load[width=simdwith](simdwith*i)
            var source_ends_batch = self.source_ends.load[width=simdwith](simdwith*i)
            var shifts_batch = self.shifts.load[width=simdwith](simdwith*i)
            var above_lower_bound = number_simd >= source_starts_batch
            var below_upper_bound = number_simd < source_ends_batch
            var is_within_bounds = below_upper_bound.__and__(above_lower_bound)
            if is_within_bounds.reduce_or():
                for j in range(simdwith):
                    if is_within_bounds[j]:
                        return (number + shifts_batch[j]).to_int()

        var number_simd_scalar = SIMD[type, 1](number)
        for i in range(simdwith*(self.mapping_size//simdwith), self.mapping_size):
            if self.source_starts[i] <= number_simd_scalar < self.source_ends[i]:
                return (number_simd_scalar + self.shifts[i]).to_int()
        return number

    fn free(self):
        self.source_starts.free()
        self.source_ends.free()
        self.shifts.free()


@value
struct OverallMapping:
    var mappings: List[Mapping]

    fn __init__(inout self, mappings: List[Mapping]):
        self.mappings = mappings
    
    fn apply_mappings(self, number: Int) -> Int:
        var mapped_number = number
        for i in range(len(self.mappings)):
            var mapping = self.mappings[i]
            mapped_number = mapping.apply_mapping(mapped_number)
        return mapped_number

    fn apply_mappings_parallelized(self, range_start: Int, input_range: Int, inout overall_min: Int):

        @parameter
        fn apply_mappings_worker(i: Int):
            var mapped_number = self.apply_mappings(range_start + i)
            if mapped_number < overall_min:
                overall_min = mapped_number
            
        parallelize[apply_mappings_worker](input_range)
    

@value
struct OverallMappingVectorizable(OverallMappingGeneric):
    var mappings: List[MappingVectorizable]

    fn __init__(inout self, mappings: List[Mapping]):
        self.mappings  = List[MappingVectorizable]()
        for i in range(len(mappings)):
            self.mappings.append(MappingVectorizable(mappings[i]))
    
    fn apply_mappings(self, number: Int) -> Int:
        var mapped_number = number
        for i in range(len(self.mappings)):
            var mapping = self.mappings[i]
            mapped_number = mapping.apply_mapping(mapped_number)
        return mapped_number

    fn apply_mappings_parallelized(self, range_start: Int, input_range: Int, inout overall_min: Int):

        @parameter
        fn apply_mappings_worker(i: Int):
            var mapped_number = self.apply_mappings(range_start + i)
            if mapped_number < overall_min:
                overall_min = mapped_number
        
        parallelize[apply_mappings_worker](input_range)
    
    fn free(self):
        for i in range(len(self.mappings)):
            self.mappings[i].free()


trait OverallMappingGeneric:
    fn apply_mappings(self, seed: Int) -> Int:
        ...
    
    fn apply_mappings_parallelized(self, range_start: Int, input_range: Int, inout overall_min: Int):
        ...


def part5a[T: OverallMappingGeneric](overall_mapping: T, seeds_int: List[Int]):
    minimum = Int(1000000000000)  # sucks that I can't do math.inf here
    for i in range(len(seeds_int)): # I hate doing for loops like this so much!
        seed = seeds_int[i]
        transformed_number = overall_mapping.apply_mappings(seed)
        if transformed_number < minimum:
            minimum = transformed_number
    print(minimum)


def part5b[T: OverallMappingGeneric](overall_mapping: T, seeds_int: List[Int]):
    minimum = Int(1000000000000)
    for seed_index in range(0, len(seeds_int), 2):
        for i in range(seeds_int[seed_index], seeds_int[seed_index] + seeds_int[seed_index + 1]):
            transformed_number = overall_mapping.apply_mappings(i)
            if transformed_number < minimum:
                minimum = transformed_number
        print("Finished seed_index " + str(seed_index))
    print("5b solutions is: " + str(minimum))


def part5b_parallelized[T: OverallMappingGeneric](overall_mapping: T, seeds_int: List[Int]):
    minimum = Int(1000000000000)
    for seed_index in range(0, len(seeds_int), 2):
        range_start = seeds_int[seed_index]
        input_range = seeds_int[seed_index + 1]
        overall_mapping.apply_mappings_parallelized(range_start, input_range, minimum)
        print("Finished seed_index " + str(seed_index) + " of " + len(seeds_int))
    print("5b solutions is: " + str(minimum)) # Takes 5 seconds on first iteration


def main():
    with open("test_file_small.txt", "r") as handle:
        text = handle.read()
        lines = text.split("\n")
        seeds_line = lines[0]
        seeds_str = seeds_line[7:]
        seeds_int = parse_list_of_ints(seeds_str)
        var mappings = List[Mapping]()
        for i in range(1, len(lines)):
            line = lines[i]
            if "map" in line:
                mappings.append(Mapping())
            elif len(line) > 0:
                row_vals = parse_list_of_ints(line)
                mappings[-1].intervals.append(ShiftInterval(source_start=row_vals[1], source_end=row_vals[1] + row_vals[2], destination_start=row_vals[0]))
        overall_mapping = OverallMapping(mappings)
        overall_mapping_vectorizable = OverallMappingVectorizable(mappings)
        
        # part5a_generic(overall_mapping, seeds_int)

        # part5a(overall_mapping_vectorizable, seeds_int)

        # part5b(overall_mapping, seeds_int)
        
        # part5b(overall_mapping_vectorizable, seeds_int)

        # part5b_parallelized(overall_mapping, seeds_int)

        part5b_parallelized(overall_mapping_vectorizable, seeds_int)

        overall_mapping_vectorizable.free()
