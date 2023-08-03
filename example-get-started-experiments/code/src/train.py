from fire import Fire
from ultralytics import YOLO


def train(epochs: int = 10, imgsz: int = 384, model: str = "yolov8n-seg.pt", **kwargs):
    yolo = YOLO(model)

    yolo.train(data="datasets/yolo_dataset.yaml", epochs=epochs, imgsz=imgsz, **kwargs)


if __name__ == "__main__":
    Fire(train)