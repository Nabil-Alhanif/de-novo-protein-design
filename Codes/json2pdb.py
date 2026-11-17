import json
import sys


# Function to convert JSON file to PDB
def json2pdb(input_json, output_pdb="output.pdb"):
    # Load the JSON file
    with open(input_json) as input_file:
        data = json.load(input_file)

    with open(output_pdb, "w") as output_file:
        output_file.write(data["output_pdb"] + "END\n")


# Kay, now, we need to take user input as I don't want to hard code anything
# https://askubuntu.com/questions/430196/how-to-pass-arguments-to-functions-while-executing-a-python-script-from-terminal

if __name__ == "__main__":
    input_json = sys.argv[1]
    output_pdb = sys.argv[2]

    # Wrap this around try catch: https://docs.python.org/3/tutorial/errors.html
    try:
        json2pdb(input_json, output_pdb)
    except Exception as inst:
        print(type(inst))  # the exception type
        print(inst.args)  # arguments stored in .args
        print(inst)  # __str__ allows args to be printed directly,
