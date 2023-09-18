import logging
import re
import sys

from sagemaker.deserializers import JSONDeserializer
from sagemaker.pytorch import PyTorchModel
from sagemaker.serverless import ServerlessInferenceConfig


memory_size = { 
    "dev": 4096 ,
    "staging": 4096,
    "prod": 6144 ,
    "default": 4096,
}
max_concurrency = { 
    "dev": 5,
    "staging": 5,
    "prod": 10,
    "default": 5,
}


def deploy(
    name: str,
    stage: str,
    version: str,
    model_data: str,
    role: str,
):
    sagemaker_logger = logging.getLogger("sagemaker")
    sagemaker_logger.setLevel(logging.DEBUG)
    sagemaker_logger.addHandler(logging.StreamHandler(sys.stdout))

    version_name =  re.sub(
        r"[^a-zA-Z0-9\-]", "-", f"{name}-{version}")

    model = PyTorchModel(
        name=version_name,
        model_data=model_data,
        framework_version="1.12",
        py_version="py38",
        role=role,
        env={
            "SAGEMAKER_MODEL_SERVER_TIMEOUT": "3600",
            "TS_MAX_RESPONSE_SIZE": "2000000000",
            "TS_MAX_REQUEST_SIZE": "2000000000",
            "MMS_MAX_RESPONSE_SIZE": "2000000000",
            "MMS_MAX_REQUEST_SIZE": "2000000000",
        },
    )

    stage_name =  re.sub(
        r"[^a-zA-Z0-9\-]", "-", f"{name}-{stage}")
    return model.deploy(
        initial_instance_count=1,
        deserializer=JSONDeserializer(),
        endpoint_name=stage_name,
        serverless_inference_config=ServerlessInferenceConfig(
            memory_size_in_mb=memory_size[stage],
            max_concurrency=max_concurrency[stage]
        )
    )


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Deploy a model to Amazon SageMaker")

    parser.add_argument("--name", type=str, required=True, help="Name of the model")
    parser.add_argument("--stage", type=str, required=True, help="Stage of the model")
    parser.add_argument("--version", type=str, required=True, help="Version of the model")
    parser.add_argument("--model_data", type=str, required=True, help="S3 location of the model data")
    parser.add_argument("--role", type=str, required=True, help="ARN of the IAM role to use")

    args = parser.parse_args()

    deploy(name=args.name, stage=args.stage, version=args.version, model_data=args.model_data, role=args.role)
