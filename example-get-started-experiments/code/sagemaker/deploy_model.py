import logging
import sys

from sagemaker.deserializers import JSONDeserializer
from sagemaker.pytorch import PyTorchModel


def deploy(
    name: str,
    model_data: str,
    role: str,
    instance_type: str = "ml.c4.large",
):
    sagemaker_logger = logging.getLogger("sagemaker")
    sagemaker_logger.setLevel(logging.DEBUG)
    sagemaker_logger.addHandler(logging.StreamHandler(sys.stdout))

    model = PyTorchModel(
        name=name,
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


    return model.deploy(
        initial_instance_count=1,
        instance_type=instance_type,
        deserializer=JSONDeserializer(),
        endpoint_name=name,
    )


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Deploy a model to Amazon SageMaker')

    parser.add_argument('--name', type=str, required=True, help='Name of the model')
    parser.add_argument('--model_data', type=str, required=True, help='S3 location of the model data')
    parser.add_argument('--role', type=str, required=True, help='ARN of the IAM role to use')
    parser.add_argument('--instance_type', type=str, default='ml.c4.xlarge', help='Type of instance to use')

    args = parser.parse_args()

    deploy(name=args.name, model_data=args.model_data, role=args.role, instance_type=args.instance_type)
