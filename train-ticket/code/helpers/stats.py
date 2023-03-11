import json, numbers, pprint
from itertools import pairwise
from itertools import chain

class Stats:

    def __init__(self, pre, post):
        with open(pre) as f1, open(post) as f2:
            self.pre = json.load(f1)
            self.post = json.load(f2)

            self.pre.extend(self.post)
            self.data = self.pre

    def split_by_newline(self, row):
        return [[int(y) for y in x.split()] for x in row.splitlines()]

    def raw_data_to_list():
        pass

    def jiffies_to_seconds(self, x):
        return x * 10**-2

    def ms_to_seconds(self, x):
        return x * 10**-3

    def ns_to_seconds(self, x):
        return x * 10**-9

    def difference(self, x, y):
        if isinstance(x, numbers.Number) and isinstance(y, numbers.Number):
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
    def __init__(self, pre, post):
        Stats.__init__(self, pre, post)
        self.data = self.__generate_stats()

    def measure_to_list(self, measure):
        return {
            k : list(
                    chain(*self.split_by_newline(v))
                ) if k != 'timestamp' else v for k, v in measure.items()
        }

    def raw_data_to_list(self):
        return [self.measure_to_list(measure) for measure in self.data]

    def calculate_utilization(self, busy, duration):
        return busy / duration / 8 * 100

    def __generate_stats(self):
        self.data = self.raw_data_to_list()
        delta = self.get_difference_among_measurements()

        output = {}
        for r in delta:
            for k, v in r.items():
                if k != 'timestamp' and k != 'docker':
                    output[k] = {
                        'cpu': self.calculate_utilization(
                            self.ns_to_seconds(v[0]), r['timestamp']
                        ),
                        'disk': round(self.ns_to_seconds(v[1]) / r['timestamp'] * 100, 3),
                        'io': v[2]
                    }

        return output

class SystemStats(Stats):
    def __init__(self, pre, post):
        Stats.__init__(self, pre, post)
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
            "io": row["disk"][1],
            "duration": row['timestamp']
        }

    def __generate_stats(self):
        self.data = self.raw_data_to_list()
        delta = self.get_difference_among_measurements()

        return [self.calculate_utilization(x) for x in delta]
