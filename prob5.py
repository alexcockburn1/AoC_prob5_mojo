from typing import List
import math
import time


def parse_list_of_ints(in_string: str) -> List[int]:
    str_list = in_string.split(" ")
    return [int(s) for s in str_list]


class ShiftInterval:
    def __init__(self, destination_start: int, source_start: int, source_end: int):
        self.source_start = source_start
        self.source_end = source_end
        self.shift = destination_start - source_start
    
    def __str__(self) -> str:
        return "ShiftInterval, shift=" + str(self.shift) + ", source_start=" + str(self.source_start) + ", source_end=" + str(self.source_end)


class Mapping:
    def __init__(self):
        self.intervals = []
    
    def apply_mapping(self, number: int) -> int:
        for i in range(len(self.intervals)):
            interval = self.intervals[i]
            if interval.source_start <= number < interval.source_end:
                return number + interval.shift
        return number


class OverallMapping:
    def __init__(self, mappings: List[Mapping]):
        self.mappings = mappings
    
    def apply_mappings(self, number: int) -> int:
        mapped_number = number
        for i in range(len(self.mappings)):
            mapping = self.mappings[i]
            mapped_number = mapping.apply_mapping(mapped_number)
        return mapped_number


def main():
    with open("test_file.txt", "r") as handle:
        text = handle.read()
        lines = text.split("\n")
        seeds_line = lines[0]
        seeds_str = seeds_line[7:]
        seeds_int = parse_list_of_ints(seeds_str)
        mappings = []
        for i in range(1, len(lines)):
            line = lines[i]
            if "map" in line:
                mappings.append(Mapping())
            elif len(line) > 0:
                row_vals = parse_list_of_ints(line)
                mappings[-1].intervals.append(ShiftInterval(source_start=row_vals[1], source_end=row_vals[1] + row_vals[2], destination_start=row_vals[0]))
        overall_mapping = OverallMapping(mappings)
        
        # minimum = 1000000000000  # sucks that I can't do math.inf here
        # for i in range(len(seeds_int)): # I hate doing for loops like this so much!
        #     seed = seeds_int[i]
        #     transformed_number = overall_mapping.apply_mappings(seed)
        #     if transformed_number < minimum:
        #         minimum = transformed_number
        # # 5a solution
        # print(minimum)

        total_numbers_to_check = sum([seed for i, seed in enumerate(seeds_int) if i % 2 != 0])
        print(f"{total_numbers_to_check=}")

        minimum = 1000000000000
        for seed_index in range(0, len(seeds_int), 2):
            start_time = time.perf_counter()
            for i in range(seeds_int[seed_index], seeds_int[seed_index] + seeds_int[seed_index + 1]):
                if i - seeds_int[seed_index] == 1000000:
                    print(f"Completed {i - seeds_int[seed_index]} in time {time.perf_counter() - start_time}")

                transformed_number = overall_mapping.apply_mappings(i)
                if transformed_number < minimum:
                    minimum = transformed_number
            print("Finished seed_index " + str(seed_index))
        print("5b solutions is: " + str(minimum))

        # number_iters = sum([val for i, val in enumerate(seeds_int) if i % 2 == 0])
        # print(number_iters)

if __name__ == "__main__":
    main()
