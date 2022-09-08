import random

import emoji
import mlem

def model(text: str):
    """
    Translate dog barks to emoji, as you hear them
    """
    return " ".join(
        random.choice(list(emoji.EMOJI_DATA.keys())) for _ in text.split()  # type: ignore
    )


if __name__ == '__main__':

    mlem.api.save(model, "models/churn.pkl", sample_data="Woof woof!", external=True)
