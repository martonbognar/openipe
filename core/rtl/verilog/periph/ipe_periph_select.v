`ifdef IPE_1REGIONS
  `include "ipe_periph_1.v"
`elsif IPE_2REGIONS
  `include "ipe_periph_2.v"
`elsif IPE_3REGIONS
  `include "ipe_periph_3.v"
`elsif IPE_4REGIONS
  `include "ipe_periph.v"
`else
  `include "ipe_periph.v"
`endif