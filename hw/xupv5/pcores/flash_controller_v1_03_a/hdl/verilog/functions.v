//
// This file is part of the Ming II source release from The Non-volatile Systems
// Laboratory at UCSD.  If you use this code in your research, please acknowledge
// the NVSL in any papers you publish.
// 
// Contact info: Steven Swanson <swanson@cs.ucsd.edu>, (858) 534 - 1743
//  
//        University of California, San Diego 
//        Department of Computer Science and Engineering 
//        9500 Gilman Drive, Dept 0114 
//        La Jolla CA 92093-0114 USA
// 
// 
// Copyright 2009-2012 The Regents of the University of California
//
function integer log2;
	input integer value;
begin
	if (value <= 2) begin
		log2 = 1;
	end else begin
		for (log2 = 0; value > 1; log2 = log2 + 1)
			value = value >> 1;
	end
end
endfunction

function integer ceil_division;
	input [31:0] a, b;
	integer remainder;
begin
	remainder = a % b;
	if (remainder != 0)
		ceil_division = (a-remainder)/b + 1;
	else
		ceil_division = a/b;
end
endfunction