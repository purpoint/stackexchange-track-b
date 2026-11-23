#!/usr/bin/env python3
"""Generate three localhost worker configurations with unique service ports."""

from pathlib import Path
import os
import shutil
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "cluster" / "config"
DESTINATION = ROOT / "cluster" / "worker-configs"
HADOOP_HOME = Path(os.environ.get("HADOOP_HOME", "/home/cse/.local/opt/hadoop-3.5.0"))


def set_property(file_path: Path, name: str, value: str) -> None:
    tree = ET.parse(file_path)
    root = tree.getroot()
    for prop in root.findall("property"):
        if prop.findtext("name") == name:
            prop.find("value").text = value
            break
    else:
        prop = ET.SubElement(root, "property")
        ET.SubElement(prop, "name").text = name
        ET.SubElement(prop, "value").text = value
    tree.write(file_path, encoding="utf-8", xml_declaration=True)


def main() -> None:
    for index in range(1, 4):
        name = f"worker{index}"
        config_dir = DESTINATION / name
        if config_dir.exists():
            shutil.rmtree(config_dir)
        shutil.copytree(SOURCE, config_dir)
        shutil.copy2(HADOOP_HOME / "etc" / "hadoop" / "log4j.properties", config_dir / "log4j.properties")
        data_root = f"/tmp/bda-hadoop/workers/{name}"
        hdfs_data_dir = "/tmp/bda-hadoop/hdfs/data" if index == 1 else f"{data_root}/hdfs/data"

        hdfs = config_dir / "hdfs-site.xml"
        worker_ip = f"127.0.0.{index + 1}"
        base_port = 9864 + (index - 1) * 10
        set_property(hdfs, "dfs.replication", "3")
        set_property(hdfs, "dfs.datanode.data.dir", f"file://{hdfs_data_dir}")
        set_property(hdfs, "dfs.datanode.hostname", worker_ip)
        set_property(hdfs, "dfs.datanode.http.address", f"0.0.0.0:{base_port}")
        set_property(hdfs, "dfs.datanode.address", f"0.0.0.0:{base_port + 2}")
        set_property(hdfs, "dfs.datanode.ipc.address", f"0.0.0.0:{base_port + 3}")

        yarn = config_dir / "yarn-site.xml"
        set_property(yarn, "yarn.nodemanager.hostname", worker_ip)
        set_property(yarn, "yarn.nodemanager.address", f"{worker_ip}:45454")
        set_property(yarn, "yarn.nodemanager.localizer.address", f"{worker_ip}:8040")
        set_property(yarn, "yarn.nodemanager.webapp.address", f"{worker_ip}:8042")
        set_property(yarn, "yarn.nodemanager.local-dirs", f"{data_root}/yarn/local")
        set_property(yarn, "yarn.nodemanager.log-dirs", f"{data_root}/yarn/logs")
        set_property(yarn, "yarn.nodemanager.resource.memory-mb", "2048")
        set_property(yarn, "yarn.scheduler.maximum-allocation-mb", "2048")
        set_property(yarn, "yarn.nodemanager.resource.cpu-vcores", "2")

        mapred = config_dir / "mapred-site.xml"
        set_property(mapred, "mapreduce.shuffle.port", str(13562 + index))
        set_property(mapred, "mapreduce.application.classpath", "${HADOOP_MAPRED_HOME}/share/hadoop/mapreduce/*,${HADOOP_MAPRED_HOME}/share/hadoop/mapreduce/lib/*,${HADOOP_COMMON_HOME}/share/hadoop/common/*,${HADOOP_COMMON_HOME}/share/hadoop/common/lib/*,${HADOOP_HDFS_HOME}/share/hadoop/hdfs/*,${HADOOP_HDFS_HOME}/share/hadoop/hdfs/lib/*,${HADOOP_YARN_HOME}/share/hadoop/yarn/*,${HADOOP_YARN_HOME}/share/hadoop/yarn/lib/*")

    print(f"Generated three co-located worker configs in {DESTINATION}")


if __name__ == "__main__":
    main()
