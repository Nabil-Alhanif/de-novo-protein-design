#import "@preview/physica:0.9.8": *

// --- Global Settings ---
#set page(
    paper: "us-letter",
    margin: (left: 0.75in, right: 0.75in, top: 1in, bottom: 1in),
    numbering: "1",
)

#set text(font: "Times New Roman", size: 12pt)
#set par(leading: 1.15em, spacing: 2em, justify: true)
#show table: set par(justify: false)
#set math.equation(numbering: "(1)")

// --- Layout Helpers ---
#let check = $ballot.check$
#let uncert = $plus.minus$
#let angstrom = "Å"

#let pm = $plus.minus$

// --- Dynamic Footer Logic ---
#set page(footer: context {
    if here().page() > 1 {
        let selector = selector(heading.where(level: 1)).before(here())
        let last-h1 = query(selector).last()

        set align(right) // Centered for appendices, can be adjusted via logic

        // Check if we are in Appendix territory
        if last-h1.supplement == [Appendix] {
            let app-letter = counter(heading).display("A")
            let page-val = counter(page).display("1")
            [#app-letter - #page-val]
        } else {
            // Normal pagination: Left justified as per your prompt
            let page-val = counter(page).display("1/1", both: true)
            [Page #page-val]
        }
    }
})


// --- Heading Styles ---
#set heading(numbering: "1.1.1")
#show heading: it => {
    // Define font size based on level
    let size = if it.level == 1 { 18pt } else if it.level == 2 { 14pt } else {
        12pt
    }

    set text(size, weight: "bold")

    let res = ""
    if it.numbering != none {
        if it.supplement == [Appendix] {
            res = it.supplement + " " + counter(heading).display() + ":"
        } else {
            res = counter(heading).display() + "."
        }
    }

    block(
        above: 1.5em,
        below: 1.2em,
    )[
        #res #h(0.3em) #it.body
    ]
}

#show figure.where(kind: table): set figure.caption(position: top)
#show figure.where(kind: image): set figure.caption(position: bottom)
#show figure.where(kind: image): set block(width: 100%)

// --- Caption Logic ---
#show figure.caption: it => {
    set align(left)
    set par(leading: 0.9em)
    it
}

#show link: it => underline(
    text(
        fill: blue,
        style: "italic",
        it,
    ),
)


// --- Document Body ---

#align(center, text(21pt)[
    *DEPARTMENT OF CHEMICAL AND BIOLOGICAL ENGINEERING*
])
#v(2em)
#figure(
    image("UBC-logo.svg"),
    kind: "ubc_logo",
    supplement: "logo",
)

#v(2em)
#align(center, text(20pt)[
    *CHBE 431 - De-Novo Protein Design*
])

#v(1.5em)

#align(center, text(18pt)[
    *Submitted by:*
])
#v(-1em)
#align(center, text(18pt)[
    *Muhamad Nabil Alhanif*
])
#v(-1em)
#align(center, text(14pt)[
    Student ID: 76787712
])

#v(3em)
#align(center, text(18pt)[
    University of British Columbia\
    Vancouver, Canada
])

#pagebreak()
#outline()

#pagebreak()
= Introduction
In this assignment, my target is to design potential protein binder for the #link("https://www.rcsb.org/structure/6M0J")[*COVID-19 Spike Protein, 6M0J*]. As usual, all related files and codes are posted through Github: https://github.com/Nabil-Alhanif/de-novo-protein-design.git

The COVID-19 Spike Protein contains two chains, A and B (auth E), with 7 small molecules. The full structure is shown below in @fig-6m0j-original. Protein A is Angiotensin-converting enzyme 2, while protein B is the Spike protein S1. Therefore, the new protein designed here should be able to bind to protein B.

#figure(
    image("Assets/6M0J Original.png", width: 50%),
    caption: [COVID-19 Spike Protein, 6M0J. Chain A is coloured blue, while Chain B is coloured magenta.],
) <fig-6m0j-original>

To achieve this overall goal, the following steps & algorithms are followed:
1. Isolate interacting area between protein A & B.
2. Use RFDiffusion to predict protein structure that can bind (interact) with this area in protein B.
3. Use ProteinMPNN to predict the amino acid structure.
4. Use AlphaFold to verify everything.

#pagebreak()
= Isolate Interacting Area in PyMOL
As we know that the protein only has 2 chains (A & B), we can delete the other 7 small molecules.

#figure(
    image("Assets/6M0J Chain Only.png", width: 50%),
    caption: [6M0J, showing only chains],
) <fig-6m0j-chain-only>

Now, to get the binding area, we will select all residues in protein B (spike protein) within 5 $angstrom$ from protein A (binding protein). By doing this, we can find residues in B that is interacting with A, and thus we can generate a new protein that will interact with this residue from B. Therefore, generating a new protein that behaves similarly to A, the current biding protein.

```python
select interface, byres (chain E within 5 of chain A)
residues = set([res.resi for res in cmd.get_model("interface").atom])
print("Residue indices:", sorted(residues))
```

Note that while the spike protein is chain B, it is authenticated as chain E in PyMOL.


#figure(
    image("Assets/fig-6m0j-binding-b.png", width: 50%),
    caption: [6M0J, residues of B within 5 $angstrom$ of A highlighted in red],
) <fig-fig-6m0j-binding-b>

The resulting residues are:

```python
Residue indices: ['417', '446', '447', '449', '453', '455', '456', '473', '475', '476', '484', '486', '487', '489', '493', '496', '498', '500', '501', '502', '505']
```

When porting to RFDiffusion, the indices have to be formatted as A283,A286 etc. Of course, doing that manually will take a while (I mean, it's likely faster than the time I spent writing this and writing the code, but cmon, we're programmer, we're here to automate stuff). So, of course, we'll use a short python command to format it!

```python
fmt = ','.join(["E" + res for res in sorted(residues)])
print(fmt)
```

Giving:

E417,E446,E447,E449,E453,E455,E456,E473,E475,E476,E484,E486,E487,E489,E493,E496,E498,
E500,E501,E502,E505

Also, I'm doing this the old-school way: by hand + stackoverflow, just because. Overflow resources used: @AppendingSameString @PythonJoinString.

Finally, we save the file as #link("https://github.com/Nabil-Alhanif/de-novo-protein-design/blob/master/PyMOL%20Files/6M0J%20to%20RFDiffusion.pdb")[6M0J to RFDiffusion.pdb]

#pagebreak()
= Generate Potential Structure in RFDiffusion
Now that we have all interacting residues, time to post this to #link("https://build.nvidia.com/ipd/rfdiffusion?snippet_tab=Try")[RFDiffusion]. From PyMOL, Chain E is numbered 333 to 526. For the target protein length, we'll do 50 - 100, just like the class sample.
#figure(
    image("Assets/rfdiffusion-nvidia-setup.png", width: 80%),
    caption: [RFDiffusion Input in NVIDIA IPC],
) <fig-rfdiffusion-nvidia-setup>

The resulting output is saved as either #link("https://github.com/Nabil-Alhanif/de-novo-protein-design/blob/master/RFDiffusion%20Output/output1.json")[JSON] or #link("https://github.com/Nabil-Alhanif/de-novo-protein-design/blob/master/RFDiffusion%20Output/output1.txt")[TXT (ASCII)].

#pagebreak()
== Making the PDB File
In class, we created the PDB file using Gen AI. Personally, I'm not a big fan; I've had experience of AI changing values when I asked it to parse a table screenshot into an actual table. So, we're gonna use python once more!

This one will require a bit more setup, but it seems to be possible based on stackoverflow...

The last post there was from 2020 though, so uhh, let's see if it's actually work :D

Of course, I'll have to verify if this method works or now. To do that, I will load the PDB file in PyMOL and see how it is.

=== Attempt 1: Direct Converseion of JSON to PDB via Pandas
Based on @HowCanConvertCsvToPdb and @PythonHowCanJsonToCsv.

Code used:

#raw(read("Codes/json2pdb-attempt1.py"), lang: "python", block: true)

Result: Yeah, the code was not successful. Turns out, although the file is a json file, the "output_pdb" portion of it is a just a normal txt file, formatted like a csv file. It's not really a JSON file, so Pandas can't read it. So, I'll do a different approach.

#pagebreak()
=== Attempt 2: Direct Conversion of TXT to PDB via Pandas
From reading a sample PDB file, they look exactly like a normal CSV file separated by spaces. Each line has a breakline "\n" character and the final line is "END". So, let's make that :D

#raw(read("Codes/json2pdb-attempt2.py"), lang: "python", block: true)


This code works properly, and the generated PDB file contains "END" as the very last row :D

However, this PDB file can't be loaded in PyMOL. Upon further inspection, it's because pandas converted some values into numbers, thus changing their decimals and messing it up. So... let's just do it with plain python!

#pagebreak()
=== Attempt 3: Use Plain Python to Convert TXT to PDB
With lessons learned from before, let's just use plain python this time...

#raw(read("Codes/json2pdb.py"), lang: "python", block: true)

To run:
```fish
python json2pdb.py "RFDiffusion Output/output1.json" "PyMOL Files/From RFDiffusion.pdb"
```

This code works :D

#figure(
    image("Assets/6M0J and RFDiffusion comp.png", width: 80%),
    caption: [Original protein (green + blue) next to new protein (yellow + red). Notice that red and blue looks the same.],
) <fig-rfdiffusion-original-comp>

#figure(
    image("Assets/6M0J and RFDiffusion overlap.png", width: 80%),
    caption: [Structure above, but overlapped. Red and blue form perfect overlap!],
) <fig-rfdiffusion-nvidia-setup>

=== Final PDB Output from RFDiffusion
Outputs from RFDiffusion are as follows:
- #link("https://github.com/Nabil-Alhanif/de-novo-protein-design/blob/master/RFDiffusion%20Output/output1.json")[output1.json]: The generated JSON file
- #link("https://github.com/Nabil-Alhanif/de-novo-protein-design/blob/master/RFDiffusion%20Output/output1.txt")[output1.txt]: The generated JSON file, but as a TXT
- #link("https://github.com/Nabil-Alhanif/de-novo-protein-design/blob/master/PyMOL%20Files/From%20RFDiffusion.pdb")[From RFDiffusion.pdb]: PDB generated by code above from the output1.json file

Everything linked and accessible through GitHub!

Note that #link("https://github.com/Nabil-Alhanif/de-novo-protein-design/blob/master/PyMOL%20Files/rfdiffusion_output.pdb")[rfdiffusion_output.pdb] is a PDB file generated by Claude that I used to compare my python output with.

#pagebreak()
= Generate Potential Amino Acid in ProteinMPNN
Now that we have the new PDB file, time to use #link("https://build.nvidia.com/ipd/proteinmpnn?snippet_tab=Try")[ProteinMPNN] to predict the amino acid structure. Here, I set sampling temperature as 0.28 as the recommended range is 0.1 - 0.3.


#figure(
    image("Assets/proteinmpnn-nvidia-setup.png", width: 80%),
    caption: [Setup for ProteinMPNN],
) <fig-proteinmpnn-nvidia-setup>

The full output is available in #link("https://github.com/Nabil-Alhanif/de-novo-protein-design/blob/master/ProteinMPNN%20Output/proteinmpnn.json")[proteinmpnn.json].

Amino acid sequence of new binding protein:

SLEKAKKILEELAKEGSEEAKEILKMSDDVRKRKGEEIEEERKREEYKKLKEELEKKIKELTEKIKKLKKEGGSEEEIKKLEEEKEKAEKILKEIEKE

#pagebreak()
= Verification in AlphaFold
Finally, we'll verify the shape of this newly-minted protein through #link("https://alphafoldserver.com/")[AlphaFold].

#figure(
    image("Assets/alphafold-setup.png", width: 100%),
    caption: [Top protein: De-novo biniding protein. Bottom protein: Original spike protein],
) <fig-alphafold-setup>


#figure(
    image("Assets/alphafold-result.png", width: 100%),
    caption: [Structure prediction result from AlphaFold. Note the high confidence level for most amino acids.],
) <fig-alphafold-result>

#pagebreak()
== AlphaFold Result Discussion

In total, AlphaFold produced #link("https://github.com/Nabil-Alhanif/de-novo-protein-design/tree/master/AlphaFold%20Output")[5 potential protein structure].

#figure(
    image("Assets/6m0j and alphafold all results.png", width: 100%),
    caption: [All generated alphafold structure overlapped. Yellow chain is the predicted structure from RFDiffusion; all other coils are from AlphaFold.],
)<fig-alphafold-full>

As all 5 AlphaFold results are similar, the structure shown in @fig-alphafold-result is assumed to be representative of the output. From @fig-alphafold-result, it can be seen that most amino acids are coloured dark blue or light blue, signifying a good confidence level. While there are some yellows, the amount is miniaml and it seems to be located in the extremities, and shouldn't affect the binding too much.

Conclusion: *Good confidence level!*.

#pagebreak()
#show bibliography: set block(above: 2em)
#show bibliography: set heading(numbering: "1")
#bibliography("references.bib")

/*
// --- Transition to Appendices ---
#pagebreak()
#counter(page).update(1)
#counter(heading).update(0)
#set heading(numbering: "A.1", supplement: [Appendix])

= Raw and Calculated Data
See attached excel and ipynb file.

#pagebreak()
= Sample Calculation
#counter(page).update(1)

#image("SampleCalcs/B-1.png")

#pagebreak()
= Error Analysis
#counter(page).update(1)
*/

// vim: set tabstop=4 shiftwidth=4 softtabstop=4 noexpandtab :
