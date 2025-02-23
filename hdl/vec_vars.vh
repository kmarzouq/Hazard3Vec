// FOR LOADING AND STORING

// For determining type of load or store
localparam UNIT_STRIDE    = 2'b00;//consecutively load/store each byte
localparam IND_UNORDER    = 2'h01;//use vector elements as offsets for load/store | DO NOT CARE ABOUT ORDER OF DATA LOADED
localparam STRIDED        = 2'h10;//use stride provided by scalar register as offset between each calc
localparam IND_ORDER      = 2'h11;//use vector elements as offsets for load/store | CARE ABOUT ORDER OF DATA LOADED

//if unit stride, what type of unit stride
localparam US_LD    = 5'b00000;//standard unit stride load
localparam US_LD    = 5'b01000;//
localparam US_LD    = 5'b01011;
localparam US_fault = 5'b10000;
