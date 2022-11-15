import sys

import mlem

if __name__ == "__main__":
    value = sys.argv[1] if len(sys.argv) > 1 else "no value"

    def model(data):
        return value

    mlem.api.save(model, "models/churn.pkl", sample_data="string")
