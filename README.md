TL;DR HOWTO INSTALL
===================

- Install opam through your favourite means.
- Double-check that no Coq-related environment variables like COQBIN or COQPATH are set.
- Launch the following commands in the folder of this development.
```
opam switch create . --empty
eval $(opam env)
opam install ocaml-base-compiler=4.11.2
opam repo --this-switch add coq-released https://coq.inria.fr/opam/released
opam install . --deps-only
make
```

IMPORTANT NOTE
==============

The coqdocjs subfolder is **not** part of this development, but an independent project vendored here for simplicity of the build process. The upstream repository can be found at https://github.com/coq-community/coqdocjs/.

Presentation
=======

This repo contains the formalisation work accompanying the paper *“Upon This Quote I Will Build My Church Thesis”*.

The formalization is based on a [previous work](https://github.com/coqhott/logrel-coq/) by Adjej et al ([*Martin-Löf à la Coq*, CPP'24](https://arxiv.org/abs/2310.06376)), which itself follows a similar [Agda formalization](https://github.com/mr-ohman/logrel-mltt/) (described in [*Decidability of conversion for Type Theory in Type Theory*, 2018](https://dl.acm.org/doi/10.1145/3158111)). In order to avoid some work on the syntax, this project uses the [AutoSubst](https://github.com/uds-psl/autosubst-ocaml) project to generate syntax-related boilerplate.

Building
===========

The project builds on Coq version `8.16.1`, see the [opam](./opam) file for complete dependencies. Since they are not available as opam packages, [coqdocjs](https://github.com/coq-community/coqdocjs/) is simply included.

Once the dependencies have been installed, you can simply issue `make` in the root folder. The development should build within 10 minutes (around 3 minutes on a modern laptop).

Apart from a few harmless warnings, and the output of some examples, the build reports on the assumptions of our main theorems, using `Print Assumptions`.

For simplicity, the html documentation built using `coqdoc` is included in the artefact. It can be built again by invoking `make coqdoc`.

Browsing the development
==================

The development, rendered using the [coqdoc](https://coq.inria.fr/refman/using/tools/coqdoc.html) utility, can be then browsed (as html files). To start navigating the sources, the best entry point is probably the [the table of content](https://ppedrot.github.io/quote-mltt-lics24/coqdoc/toc.html). A [short description of the file contents](https://ppedrot.github.io/quote-mltt-lics24/index.md) is also provided to make the navigation easier.

Files of interest
=================

Definitions
--------

The abstract syntax tree of terms is in [Ast](https://ppedrot.github.io/quote-mltt-lics24/coqdoc/LogRel.AutoSubst.Ast.html), the declarative typing and conversion predicates are in [DeclarativeTyping](https://ppedrot.github.io/quote-mltt-lics24/coqdoc/LogRel.DeclarativeTyping.html), reduction is in [UntypedReduction](https://ppedrot.github.io/quote-mltt-lics24/coqdoc/LogRel.UntypedReduction.html).

The logical relation is defined with respect to a generic notion of typing, given in [GenericTyping](https://ppedrot.github.io/quote-mltt-lics24/LogRel.GenericTyping.html).

Proofs
----------

The toplevel results are exposed in a standalone file [Main](https://ppedrot.github.io/quote-mltt-lics24/coqdoc/LogRel.Main.html).

The logical relation is defined in [LogicalRelation](https://ppedrot.github.io/quote-mltt-lics24/coqdoc/LogRel.LogicalRelation.html). It is first defined component by component, before the components are all brought together by inductive `LR` at the end of the file. The fundamental lemma of the logical relation, saying that every well-typed term is reducible, is in [Fundamental](https://ppedrot.github.io/quote-mltt-lics24/coqdoc/LogRel.Fundamental.html).

Injectivity and no-confusion of type constructor, and subject reduction, are proven in [TypeConstructorsInj](https://ppedrot.github.io/quote-mltt-lics24/coqdoc/LogRel.TypeConstructorsInj.html).

Consistency and canonicity are derived in [Consequences](https://ppedrot.github.io/quote-mltt-lics24/coqdoc/LogRel.Consequences.html).
