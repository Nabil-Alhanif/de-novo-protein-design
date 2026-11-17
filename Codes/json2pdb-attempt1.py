import json
import pandas as pd
import sys


# Function to convert JSON file to PDB
def json2pdb(input_json, output_pdb="output.pdb"):
    # Load the JSON file
    with open(input_json) as inputfile:
        data = json.load(inputfile)

    print("DATAAAAAA")
    print(data["output_pdb"])

    # Source - https://stackoverflow.com/a/37307324
    # Posted by vmg, modified by community. See post 'Timeline' for change history
    # Retrieved 2026-11-17, License - CC BY-SA 4.0

    # Source - https://stackoverflow.com/a/66584077
    # Posted by daniburgo, modified by community. See post 'Timeline' for change history
    # Retrieved 2026-11-17, License - CC BY-SA 4.0

    try:
        df = pd.json_normalize(data["output_pdb"])
    except Exception as inst:
        return

    # Source - https://stackoverflow.com/a/63180312
    # Posted by Vishesh Mangla, modified by community. See post 'Timeline' for change history
    # Retrieved 2026-11-17, License - CC BY-SA 4.0
    df.to_csv("test2.pdb", sep="\t")


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
