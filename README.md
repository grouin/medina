# medina
Medical Information Anonymization

## Documentation ##

MEDINA is a toolbox to de-identify texts, originally designed for
clinical texts. This toolbox aims at de-identifying data using linear
chain CRF (Wapiti tool) and producing statistical models without any
form of surface (strictly no learning of tokens, but basic features
based on tokens are used: upper/lower case, presence of digits,
punctuation marks, etc.) in order to share models (since there is no
nominative data in the models).

Files:

* lanceur.sh: all useful commands to process the data (assuming
  existing annotated data in corpus/appr/ and corpus/test/ files
  containing both *{ann,txt} files)

* zero_alignement.pl: converts BRAT annotations into embedded
  annotations (*.tag files are created); allows to manage both layered
  and discontinuous entities

* zero_tabulaire.pl: produces tabular files based on previous files,
  using a BIO schema useful for CRF tools

* zero_config.tpl: configuration template for Wapiti tool

* post_differences.pl: highlights false positive and false negative
  from the prediction file produced by Wapiti

## License ##

This toolbox is licenced under the term of the two-clause BSD Licence:

    Copyright (c) 2019  CNRS
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:
        * Redistributions of source code must retain the above
          copyright notice, this list of conditions and the following
          disclaimer.
        * Redistributions in binary form must reproduce the above
          copyright notice, this list of conditions and the following
          disclaimer in the documentation and/or other materials
          provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
    CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
    MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
    BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
    TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
    ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
    TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
    THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
    SUCH DAMAGE.

## Contact ##

For help and feedback please contact the author below:

* Grouin Cyril       &lt;cyril.grouin@limsi.fr&gt;
