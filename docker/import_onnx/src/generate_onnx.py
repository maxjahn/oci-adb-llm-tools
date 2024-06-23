#!/opt/venv/bin/python

import argparse
import re

from oml.utils import EmbeddingModel, EmbeddingModelConfig

parser = argparse.ArgumentParser(description="Convert Huggingface models to ONNX")
parser.add_argument(
    "-m", "--model", nargs="+", help="modelname in the format repo/model"
)

parser.add_argument(
    "-s",
    "--sequencelength",
    nargs="*",
    type=int,
    help="sequence length for import of models with template",
)

parser.add_argument(
    "-l", "--list-models", action="store_true", help="list pretrained models available"
)

args = parser.parse_args()

models = args.model
sequence_length = args.sequencelength

pretrained_models = EmbeddingModelConfig.show_preconfigured()

if args.list_models:
    for model in pretrained_models:
        print(model)
    quit()

if not args.model:
    print("no model specified!")
    quit()


i = -1

for model in models:
    i = i + 1

    if model in pretrained_models:
        print("import pretrained mnodel " + model)
        em = EmbeddingModel(model_name=model)
        em.export2file(re.sub("(-|\/)", model), output_dir="/opt/build/shared/models")
    else:
        try:
            print(
                "import from template "
                + model
                + " with max sequence length "
                + str(sequence_length[i])
            )
        except:
            print("import from template requires sequence length parameter!")
            quit()

        config = EmbeddingModelConfig.from_template(
            "text", max_seq_length=sequence_length[i], trust_remote_code=True
        )
        em = EmbeddingModel(model_name=model, config=config)
        em.export2file(re.sub("(-|\/)", model), output_dir="/opt/build/shared/models")
