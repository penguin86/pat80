# Memory Decoding logic
This folder contains the memory decoding logic used by Pat80.
The memory map is a simple 32k ram / 32k rom obtained using the MSB as EN signal.
The I/O space is split in 8 devices (each with 32 registers).
Pat80 doesn't use the [high address lines I/O hack](https://retrocomputing.stackexchange.com/questions/7782/z80-16-bit-i-o-port-addresses) but adheres to the official Z80 I/O documentation.

## License
All files contained in this folder are part of Pat80 Blueprints.

Pat80 Blueprints is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Pat80 Blueprints is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTYwithout even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Pat80 Blueprints.  If not, see <http://www.gnu.org/licenses/>.