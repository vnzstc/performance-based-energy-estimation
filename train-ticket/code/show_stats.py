import argparse, json
from itertools import pairwise

def per_cpu(data):
    return {f'cpu{i}': list(map(int, x)) for i, x in enumerate(list(map(str.split, data.splitlines())))}

"""
def per_cpu(data):
    return {f'cpu{i}': int(x) for i, x in enumerate(data.splitlines())}
"""

def disk(data):
    t, r = data.split()
    return {'disk-time': int(t), 'io-reqs': int(r)}

def clean(data):
    return [{'timestamp': r['timestamp'], **per_cpu(r['cpu']), **disk(r['disk'])} for r in data]

def lprint(a):
    for i, s in enumerate(a):
        print(f"##{i}\t", *s)

def main(data):
    data = clean(data)
    cpu_util = lambda x: (x[0] - x[1])/x[0]

    delta = [
        {k:(y[k]-x[k]) if not isinstance(x[k], list) else list(map(lambda z: z[1] - z[0], zip(x[k], y[k]))) for k in x.keys()} for x,y in pairwise(data)
    ]

    cpu = [[round(cpu_util(x[f"cpu{i}"]) * 100, 3) for i in range(0, 9)] for x in delta]
    lprint(cpu)

    #cpu = [[round(cpu_util(x[f"cpu{i}"]) * 100, 6) for i in range(0, 9)] for x in data]
    #disk = [[ round(x["disk-time"]*10**-3/x['timestamp']*100, 3), x["io-reqs"]] for x in delta]
    #disk = [[x["disk-time"]*10**-2/x["cpu0"][0], x["io-reqs"]] for x in delta]
    #lprint([x + y for x, y in zip(cpu, disk)])

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file", dest="file", required=True)
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()

    with open(args.file) as f:
        data = json.load(f)
        main(data)
