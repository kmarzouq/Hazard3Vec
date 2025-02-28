// FOR LOADING AND STORING
parameter XLEN            = 32,
// For determining type of load or store
parameter UNIT_STRIDE    = 2'b00, //consecutively load/store each byte
parameter IND_UNORDER    = 2'b01, //use vector elements as offsets for load/store | DO NOT CARE ABOUT ORDER OF DATA LOADED
parameter STRIDED        = 2'b10, //use stride provided by scalar register as offset between each calc
parameter IND_ORDER      = 2'b11, //use vector elements as offsets for load/store | CARE ABOUT ORDER OF DATA LOADED

//if unit stride, what type of unit stride LOAD
parameter US_LD    = 5'b00000, //standard unit stride load (load up to VL elements)
parameter US_WLD    = 5'b01000, // unit stride whole register load (ignore VL and load all elements into vector register)
parameter US_LD8    = 5'b01011, // unit stride mask load EEW=8 
parameter US_fault = 5'b10000, //unit stride fault-only-first

//if unit stride, what type of unit stride STORE
parameter US_ST    = 5'b00000, //standard unit stride load (store up to VL elements)
parameter US_WST    = 5'b01000, // unit stride whole register store (ignore VL and store all elements into mem)
parameter US_ST8    = 5'b01011 // unit stride mask store EEW=8 
