function  ii = findnear(val,locs)
% ii = findnear(val,locs)
%
% Trouve l'indice dans le vecteur locs
% de la valeur la plus proche de val 
% output	ii = indice
%
% input		(val,locs)
%		val = valeur donnée
%		locs = vecteur dans lequel chercher
%


% Copyright (C) 2005 Bernard Giroux
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
% 
% 



%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Egal
k = find(val == locs);

if isempty(k)==0
  ii = k;
  return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Inf

mink=min(abs(locs-val));
ii = find(abs(locs-val)==mink);
