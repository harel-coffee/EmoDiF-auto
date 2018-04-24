function varargout = nii_xform(src, target, rst, intrp, missVal)
% Transform a NIfTI into different resolution, or into a template space.
% 
%  NII_XFORM('source.nii', 'template.nii', 'result.nii')
%  NII_XFORM(nii, 'template.nii', 'result.nii')
%  NII_XFORM('source.nii', [1 1 1], 'result.nii')
%  nii = NII_XFORM('source.nii', 'template.nii');
%  NII_XFORM('source.nii', {'template.nii' 'source2template.mat'}, 'result.nii')
%  NII_XFORM('source.nii', {'template.nii' 'source2template_warp.nii.gz'}, 'result.nii')
%  NII_XFORM('source.nii', 'template.nii', 'result.nii', 'nearest', 0)
% 
% NII_XFORM transforms the source NIfTI, so it has the requested resolution or
% has the same dimension and resolution as the template NIfTI.
% 
% Input (first two mandatory):
%  1. source file (nii, hdr or gz versions) or nii struct to be transformed.
%  2. The second input determines how to transform the source file:
%    (1) If it is a vector of length 3, [2 2 2] for example, it will be treated
%         as requested resolution in millimeter. The result will be in the same
%         coordinate system as the source file.
%    (2) If it is a nii file name, a nii struct, or nii hdr struct, it will be
%        used as the template. The result will have the same dimension and
%        resolution as the template. The source file and the template must have
%        at least one common coordinate system, otherwise the transformation
%        doesn't make sense, and it will err out. With different coordinate
%        systems, a transformation to align the two dataset is needed, which is
%        the next case.
%    (3) If the input is a cell containing two file names, it will be
%        interpreted as a template nii file and a transformation. The
%        transformation can be a FSL-style .mat file with 4x4 transformation
%        matrix which aligns the source data to the template, in format of:
%          0.9983  -0.0432  -0.0385  -17.75  
%          0.0476   0.9914   0.1216  -14.84  
%          0.0329  -0.1232   0.9918  111.12  
%          0        0        0       1  
%        The transformation can also be a FSL-style warp nii file incorporating
%        both linear and no-linear transformation from the source to template.
%  3. result file name. If not provided or empty, nii struct will be returned.
%     This allows to use the returned nii in script without saving to a file.
%  4. interpolation method, default 'linear'. It can also be one of 'nearest',
%     'cubic' and 'spline'.
%  5. value for missing data, default NaN. This is the value assigned to the
%     location in template where no data is available in the source file.
% 
% Output (optional): nii struct.
%  NII_XFORM will return the struct if the output is requested or result file
%  name is not provided.
% 
% Please note that, once the transformation is applied to functional data, it is
% normally invalid to perform slice timing correction. Also the data type is
% changed to single unless the interpolation is 'nearest'.
% 
% See also NII_VIEWER, NII_TOOL, DICM2NII

% By Xiangrui Li (xiangrui.li@gmail.com)
% History(yymmdd):
% 151024 Write it.
% 160531 Remove narginchk so work for early matlab.
% 160907 allow src to be nii struct.
% 160923 allow target to be nii struct or hdr; Take care of logical src img.
% 161002 target can also be {tempFile warpFile}.

if nargin<2 || nargin>5, help('nii_xform'); error('Wrong number of input.'); end
if nargin<3, rst = []; end
if nargin<4 || isempty(intrp), intrp = 'linear'; end
if nargin<5 || isempty(missVal), missVal = nan; end
intrp = lower(intrp);
    
if isstruct(src), nii = src;
else nii = nii_tool('load', src);
end

if isstruct(target) || ischar(target) || (iscell(target) && numel(target)==1)
    hdr = get_hdr(target);
elseif iscell(target)
    hdr = get_hdr(target{1});
    if hdr.sform_code>0, R0 = [hdr.srow_x; hdr.srow_y; hdr.srow_z; 0 0 0 1];
    elseif hdr.qform_code>0, R0 = quat2R(hdr);
    end

    [~, ~, ext] = fileparts(target{2});
    if strcmpi(ext, '.mat') % template and xform file names
        R = load(target{2}, '-ascii');
        if ~isequal(size(R), [4 4]), error('Invalid transformation file.'); end
    else % template and warp file names
        warp_img_fsl = nii_tool('img', target{2});
        if ~isequal(size(warp_img_fsl), [hdr.dim(2:4) 3])
            error('warp file and template file img size don''t match.');
        end
        R = eye(4);
    end
    
    if nii.hdr.sform_code>0
        R1 = [nii.hdr.srow_x; nii.hdr.srow_y; nii.hdr.srow_z; 0 0 0 1];
    elseif nii.hdr.qform_code>0
        R1 = quat2R(nii.hdr);
    end

    % I thought it is something like R = R0 \ R * R1; but it is way off. It
    % seems the translation info in src nii is irrevelant, but direction must be
    % used: Left-handed storage and Right-handed storage give exactly the same
    % alignment R with the same target nii (left-handed). Alignment R may not be
    % diag-major, and can be negative for major axes (e.g. cor/sag slices).

    % Following works for tested FSL .mat and warp.nii files: Any better way?
    % R0: target;   R1: source;  R: xform;  result is also R
    R = R0 / diag([hdr.pixdim(2:4) 1]) * R * diag([nii.hdr.pixdim(2:4) 1]);
    [~, i1] = max(abs(R1(1:3,1:3)));
    [~, i0] = max(abs(R(1:3,1:3)));
    flp = sign(R(i0+[0 4 8])) ~= sign(R1(i1+[0 4 8]));
    if any(flp)
        rotM = diag([1-flp*2 1]);
        rotM(1:3,4) = (nii.hdr.dim(2:4)-1) .* flp;
        R = R / rotM;
    end
elseif isnumeric(target) && numel(target)==3 % new resolution in mm
    hdr = nii.hdr;
    ratio = target(:)' ./ hdr.pixdim(2:4);
    hdr.pixdim(2:4) = target;
    hdr.dim(2:4) = round(hdr.dim(2:4) ./ ratio);
    if hdr.sform_code>0
        hdr.srow_x(1:3) = hdr.srow_x(1:3) .* ratio;
        hdr.srow_y(1:3) = hdr.srow_y(1:3) .* ratio;
        hdr.srow_z(1:3) = hdr.srow_z(1:3) .* ratio;
    end
else
    error('Invalid template or resolution input.');
end

if ~iscell(target) 
    s = hdr.sform_code;
    q = hdr.sform_code;
    if s>0 && any(s == [nii.hdr.sform_code nii.hdr.qform_code])
        R0 = [hdr.srow_x; hdr.srow_y; hdr.srow_z; 0 0 0 1];
        frm = s;
    elseif any(q == [nii.hdr.sform_code nii.hdr.qform_code])
        R0 = quat2R(hdr);
        frm = q;
    else
        error('No matching transformation between source and template.');
    end

    if nii.hdr.sform_code == frm
        R = [nii.hdr.srow_x; nii.hdr.srow_y; nii.hdr.srow_z; 0 0 0 1];
    else
        R = quat2R(nii.hdr);
    end
end

d = single(hdr.dim(2:4));
I = ones([d 4], 'single');
[I(:,:,:,1), I(:,:,:,2), I(:,:,:,3)] = ndgrid(0:d(1)-1, 0:d(2)-1, 0:d(3)-1);
I = permute(I, [4 1 2 3]);
I = reshape(I, [4 prod(d)]);  % template ijk
if exist('warp_img_fsl', 'var')
    warp_img_fsl = reshape(warp_img_fsl, [prod(d) 3])';
    if det(R0(1:3,1:3))<0, warp_img_fsl(1,:) = -warp_img_fsl(1,:); end % correct?
    warp_img_fsl(4,:) = 0;
    I = R \ (R0 * I + warp_img_fsl) + 1; % ijk+1 (fraction) in source
else
    I = R \ (R0 * I) + 1; % ijk+1 (fraction) in source
end
I = reshape(I(1:3,:)', [d 3]);

d48 = size(nii.img); % in case of RGB
d48(numel(d48)+1:4) = 1; d48(1:3) = [];
if islogical(nii.img)
    img = nii.img;
    nii.img = false([d d48]);
    intrp = 'nearest'; missVal = 0;
elseif strcmp(intrp, 'nearest')
    img = nii.img;
    nii.img = zeros([d d48], class(img)); %#ok
else
    img = single(nii.img);
    nii.img = zeros([d d48], 'single');
end
for i = 1:prod(d48)
    nii.img(:,:,:,i) = interp3(img(:,:,:,i), I(:,:,:,2), I(:,:,:,1), I(:,:,:,3), intrp, missVal);
end

% copy xform info from template to rst nii
nii.hdr.pixdim(1:4) = hdr.pixdim(1:4);
flds = {'qform_code' 'sform_code' 'srow_x' 'srow_y' 'srow_z' ...
    'quatern_b' 'quatern_c' 'quatern_d' 'qoffset_x' 'qoffset_y' 'qoffset_z'};
for i = 1:numel(flds), nii.hdr.(flds{i}) = hdr.(flds{i}); end

if ~isempty(rst), nii_tool('save', nii, rst); end
if nargout || isempty(rst), varargout{1} = nii_tool('update', nii); end

%% quatenion to xform_mat
function R = quat2R(hdr)
b = hdr.quatern_b;
c = hdr.quatern_c;
d = hdr.quatern_d;
a = sqrt(1-b*b-c*c-d*d);
R = [1-2*(c*c+d*d)  2*(b*c-d*a)     2*(b*d+c*a);
     2*(b*c+d*a)    1-2*(b*b+d*d)   2*(c*d-b*a);
     2*(b*d-c*a )   2*(c*d+b*a)     1-2*(b*b+c*c)];
R = R * diag(hdr.pixdim(2:4));
if hdr.pixdim(1)<0, R(:,3) = -R(:,3); end % qfac
R = [R [hdr.qoffset_x hdr.qoffset_y hdr.qoffset_z]'; 0 0 0 1];

%% 
function hdr = get_hdr(in)
if iscell(in), in = in{1}; end
if isstruct(in)
    if isfield(in, 'hdr') % nii input
        hdr = in.hdr;
    elseif isfield(in, 'sform_code') % hdr input
        hdr = in;
    else
        error('Invalid input: %s', inputname(1));
    end
else % template file name
    hdr = nii_tool('hdr', in);
end
