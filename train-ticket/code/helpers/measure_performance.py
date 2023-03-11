import sys, signal
import argparse
import time
import csv, json
from resource_profiler import ResourceProfiler

def get_data(systat):
    if args.containers:
        data = {
            args.containers[c] : systat.get_containers(c) for c in args.containers
        }

        return data | {"docker": systat.get_docker() } | {'timestamp' : time.time()}

    cpu, disk = systat.get_sys()

    return {
        'cpu'      : cpu,
        'disk'     : disk
    } | {'timestamp' : time.time()}

def get_stats(profiler):
    output_file = open(args.file, 'w', encoding="utf-8")
    data = []

    def stop_profiling(*args):
        json.dump(data, output_file) # writes retrieved data

        output_file.close()
        profiler.close()

        print(f"Profiler_Stopped: {profiler.resource}")
        sys.exit()


    if args.delay:
        signal.signal(signal.SIGINT, stop_profiling)

        while True:
            data.append(get_data(profiler))
            time.sleep(float(args.delay))
    else:
        data.append(get_data(profiler))
        stop_profiling()

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--password", dest="password", required=True)
    parser.add_argument("-c", "--containers", dest="containers")
    parser.add_argument("-f", "--file", dest="file", required=True)
    parser.add_argument("-d", "--delay", dest="delay")

    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    profiler = ResourceProfiler("system", args.password)

    if args.containers:
        with open(args.containers, mode='r') as i:
            reader = csv.reader(i)
            args.containers = {rows[0]:rows[1] for rows in reader}
            profiler.resource = "containers"

    get_stats(profiler)
