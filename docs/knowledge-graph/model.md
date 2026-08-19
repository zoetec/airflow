# Grafo de conhecimento

`SearchQuery -> discovers -> CandidateSource`
`SourceSpreadsheet -> imports -> SourceCatalog`
`CandidateSource -> reconciles_with -> SourceCatalog`
`SourceCatalog -> authorizes -> CollectionRun`
`CollectionRun -> preserves -> Evidence`
`Evidence -> produces -> ListingRaw`
`ListingRaw -> normalizes_to -> PropertyOffer`

Toda relação registra fonte, horário e estado de aprovação.
