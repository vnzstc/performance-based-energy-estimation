from fabric import Connection

#cat $CPUPATH; awk -e '/^Total/ {{print $2}}' $DISKPATH $IOPATH """
#awk -F' ' '{{sum += $2}}END{{print sum}}' $CPUPATH; awk -e '/^Total/ {{print $2}}' $DISKPATH $IOPATH"""

class Commands:
    CMDS = {
        'cpu': """awk -e '/cpu[0-9]? / {print $2+$3+$4+$5+$6+$7+$8+$9+$10,$5}' /proc/stat""",
        'disk': """awk '/sda / { print $13,$4+$8 }' /proc/diskstats""",
        'docker': """
            CPUPATH=/sys/fs/cgroup/cpuacct/docker/cpuacct.usage
            cat $CPUPATH
        """,
        'containers': """
            CPUPATH=/sys/fs/cgroup/cpuacct/docker/{element}*/cpuacct.usage
            DISKPATH=/sys/fs/cgroup/blkio/docker/{element}*/blkio.io_service_time
            IOPATH=/sys/fs/cgroup/blkio/docker/{element}*/blkio.io_serviced

            cat $CPUPATH; awk -e '/^Total/ {{print $2}}' $DISKPATH $IOPATH"""
    }

class ResourceProfiler(Commands):
    def __init__(self, resource, password):
        self.c =  Connection('145.108.225.7', 'vincenzo', connect_kwargs={'password': password, 'banner_timeout': 200})
        self.resource = resource

    def get_sys(self):
        cpu = self.get_data(self.CMDS.get('cpu')).stdout
        disk = self.get_data(self.CMDS.get('disk')).stdout
        return [cpu, disk]

    def get_containers(self, container):
        return self.get_data(self.CMDS.get('containers').format(element=container)).stdout

    def get_docker(self):
        return self.get_data(self.CMDS.get('docker')).stdout

    def get_data(self, cmd):
        return self.c.run(cmd, hide=True, shell=True)

    def close(self):
        self.c.close()
