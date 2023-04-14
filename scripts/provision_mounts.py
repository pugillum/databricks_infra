"""
This file is used to run versioned maintenance jobs on the environments

Each maintenance function should map to one specific version after which the stored
version will be incremented.

Additional paths or settings can be added as parameters though this is primarily
envisioned to support schema migration for the output data in the data_export path

"""
import logging
import os
import pathlib
import sys
from argparse import ArgumentParser
from dataclasses import dataclass
from typing import Any, List

import yaml
from pyspark.sql import SparkSession

logger = logging.getLogger("provision_mounts")


@dataclass
class MountConfig:
    source: str
    mount_point: str


@dataclass
class Config:
    client_id: str
    secret_scope: str
    client_secret_ref: str
    mounts: List[MountConfig]


def _get_dbutils(spark: SparkSession) -> Any:
    try:
        from pyspark.dbutils import DBUtils  # noqa

        if "dbutils" not in locals():
            utils = DBUtils(spark)
            return utils
        else:
            return locals().get("dbutils")
    except ImportError:
        return None


def create_mount(
    dbutils: Any,
    tenant: str,
    secret_scope: str,
    client_id: str,
    client_secret_ref: str,
    source: str,
    mount_point: str,
) -> None:
    client_secret = dbutils.secrets.get(secret_scope, client_secret_ref)

    if source.startswith("adl"):
        configs = {
            "fs.adl.oauth2.access.token.provider.type": "ClientCredential",
            "fs.adl.oauth2.client.id": client_id,
            "fs.adl.oauth2.credential": client_secret,
            "fs.adl.oauth2.refresh.url": f"https://login.microsoftonline.com/{tenant}/oauth2/token",
        }
    elif source.startswith("abfss"):
        configs = {
            "fs.azure.account.auth.type": "OAuth",
            "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
            "fs.azure.account.oauth2.client.id": client_id,
            "fs.azure.account.oauth2.client.secret": client_secret,
            "fs.azure.account.oauth2.client.endpoint": f"https://login.microsoftonline.com/{tenant}/oauth2/token",
        }
    else:
        raise ValueError(f"Unknown mount source: '{source}'")

    logger.info(f"Creating mount point {mount_point} from source {source}")
    dbutils.fs.mount(source=source, mount_point=mount_point, extra_configs=configs)


def main(conf_file: str) -> None:
    logger.info(f"conf_file {conf_file}")
    spark = SparkSession.builder.getOrCreate()
    dbutils = _get_dbutils(spark)

    # load config
    config_dict = yaml.safe_load(pathlib.Path(conf_file).read_text())
    tenant_id = config_dict["tenant_id"]
    client_id = config_dict["client_id"]
    secret_scope = config_dict["secret_scope"]
    client_secret_ref = config_dict["client_secret_ref"]

    # get list of mounts
    mount_points = [mount.mountPoint for mount in dbutils.fs.mounts()]

    # iterate through mounts
    for mount in config_dict["mounts"]:
        if mount["mount_point"] not in mount_points:
            create_mount(
                dbutils=dbutils,
                tenant=tenant_id,
                secret_scope=secret_scope,
                client_id=client_id,
                client_secret_ref=client_secret_ref,
                source=mount["source"],
                mount_point=mount["mount_point"],
            )

    logging.shutdown()


if __name__ == "__main__":
    # Parse arguments
    sys_args = sys.argv[1:]

    parser = ArgumentParser()
    parser.add_argument("--conf-file", type=str)

    args_dict = vars(parser.parse_args(sys_args))

    # initialise logging configuration
    logging.basicConfig(
        format="%(asctime)s [%(funcName)s] %(levelname)s - %(message)s",
        level=logging.INFO,
    )
    logging.getLogger("py4j").setLevel(logging.ERROR)

    main(args_dict["conf_file"])
