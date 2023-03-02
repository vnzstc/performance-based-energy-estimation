import json
from itertools import pairwise
from itertools import chain

class Stats:
    def __init__(self, file):
        with open(file) as f:
            self.data = json.load(f)

    def split_by_newline(self, row):
        return [[int(y) for y in x.split()] for x in row.splitlines()]

    def raw_data_to_list():
        pass

    def ms_to_seconds(self, x):
        return x * 10**-3

    def ns_to_seconds(self, x):
        return x * 10**-9

    def difference(self, x, y):
        if isinstance(x, int) and isinstance(y, int):
            return y - x

        return [self.difference(k, v) for k, v in zip(x, y)]

    def get_difference_list(self, x, y):
        return { k : self.difference(x[k], y[k]) for k in x.keys() }

    def get_difference_among_measurements(self):
        return [
            self.get_difference_list(x, y) for x, y in pairwise(self.data)
        ]

    def calculate_utilization(self):
        pass

    def __generate_stats(self):
        pass

class ContainerStats(Stats):
    def __init__(self, file):
        Stats.__init__(self, file)
        self.data = self.__generate_stats()

    def measure_to_list(self, measure):
        return {
            k : list(
                    chain(*self.split_by_newline(v))
                ) if k != 'timestamp' else v for k, v in measure.items()
        }

    def raw_data_to_list(self):
        return [self.measure_to_list(measure) for measure in self.data]

    def __generate_stats(self):
        self.data = self.raw_data_to_list()
        print(self.data)

        #delta = self.get_difference_among_measurements()
        #print(delta)

class SystemStats(Stats):
    def __init__(self, file):
        Stats.__init__(self, file)
        self.data = self.__generate_stats()

    def measure_to_list(self, measure):
        return {
            'timestamp': measure['timestamp'],
            'cpu' : self.split_by_newline(measure['cpu']),
            'disk': self.split_by_newline(measure['disk'])[0]
        }

    def raw_data_to_list(self):
        return [self.measure_to_list(measure) for measure in self.data]

    def calculate_cpu_utilization(self, busy, idle):
        usage = (busy - idle)/busy
        return round(usage * 100, 3)

    def calculate_disk_utilization(self, busy, period):
        usage = self.ms_to_seconds(busy)/period
        return round(usage * 100, 3)

    def calculate_utilization(self, row):
        return {
            f"cpu{i}": self.calculate_cpu_utilization(
                            row[f"cpu"][i][0], row[f"cpu"][i][1],
                        ) for i in range(0, 9)
        } | {
            "disk": self.calculate_disk_utilization(
                        row["disk"][0], row['timestamp']
                    ),
            "io": row["disk"][1]
        }

    def __generate_stats(self):
        self.data = self.raw_data_to_list()
        delta = self.get_difference_among_measurements()

        return [self.calculate_utilization(x) for x in delta]
