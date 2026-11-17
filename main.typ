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
Residue indices: ['283', '286', '417', '446', '447', '449', '453', '455', '456', '473', '475', '476', '484', '486', '487', '489', '493', '496', '498', '500', '501', '502', '505']
```

When porting to RFDiffusion, the indices have to be formatted as A283,A286 etc. Of course, doing that manually will take a while (I mean, it's likely faster than the time I spent writing this and writing the code, but cmon, we're programmer, we're here to automate stuff). So, of course, we'll use a short python command to format it!

```python
fmt = ','.join(["A" + res for res in residues])
print(fmt)
```

Giving:

A489,A496,A476,A500,A456,A486,A484,A493,A417,A453,A498,A283,A447,A286,A505,A473,
A475,A455,A487,A501,A446,A449,A502

Also, I'm doing this the old-school way: by hand + stackoverflow, just because. Overflow resources used: @AppendingSameString @PythonJoinString.

Finally, we save the file.

= Generate Potential Structure in RFDiffusion

= Generate Potential Amino Acid in ProteinMPNN

= Verification in AlphaFold

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
