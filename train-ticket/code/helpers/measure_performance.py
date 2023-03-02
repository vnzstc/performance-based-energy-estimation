import sys, signal
import argparse
import time
import csv, json
from resource_profiler import ResourceProfiler

def get_data(systat):
    t0 = int(time.time())

    if args.containers:
        data = {
            args.containers[c] : systat.get_docker(c) for c in args.containers
        } 

        t1 = int(time.time())

        return data | { 'timestamp' : t1 - t0 }

    cpu, disk = systat.get_sys()
    t1 = int(time.time())

    return {
        'cpu'      : cpu,
        'disk'     : disk
    } | {'timestamp' : t1 - t0}

def get_stats():
    outfile = open(args.file, 'w', encoding="utf-8")
    systat  = ResourceProfiler(args.password)
    data = []

    def signal_handler(*args):
        json.dump(data, outfile) # writes retrieved data
        outfile.close()
        systat.close()
        print(f"Performance Profiled: {len(data)}")
        sys.exit()

    signal.signal(signal.SIGINT, signal_handler)

    while True:
        data.append(get_data(systat))

        if args.delay:
            time.sleep(float(args.delay))

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--password", dest="password", required=True)
    parser.add_argument("-c", "--containers", dest="containers")
    parser.add_argument("-f", "--file", dest="file", required=True)
    parser.add_argument("-d", "--delay", dest="delay")
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()

    if args.containers:
        with open(args.containers, mode='r') as i:
            reader = csv.reader(i)
            args.containers = {rows[0]:rows[1] for rows in reader}

    get_stats()
