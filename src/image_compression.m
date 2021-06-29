%% 1.��ȡbmpλͼ������ͼ��ĳ���ȫΪ8�ı���
originBMP = imread('..\img\1.bmp'); % ������Ҫѹ����ͼ��·��
figure(),imshow(originBMP),title("origin bitmap image");
[origin_height,origin_width,~] = size(originBMP);
resizeBMP = resize(originBMP);

%% 2.RGBת��ΪYCbCr, ��������ɫ�²���
imgYCbCr = rgb2ycbcr(resizeBMP);     
[imgY,imgCb,imgCr] = downSample(imgYCbCr);

%% 3.ͼ��ֳ�8*8��С��ֱ����dct�任����
[dctY,dctCb,dctCr] = blockdct(imgY,imgCb,imgCr);

%% 4.�����������������
[qdctY,qdctCb,qdctCr] = quantify(dctY,dctCb,dctCr);
% %������
% [iqdctY,iqdctCb,iqdctCr] = inv_quantify(qdctY,qdctCb,qdctCr);
% %��dct
% [iy,icb,icr] = inv_blockdct(iqdctY,iqdctCb,iqdctCr);
% iYCbCr = regenerate_Ycbcr(iy,icb,icr);
% figure(),imshow(iYCbCr),title("YCbCr image(after 4:2:0 downsample and quantify)");
% irgb = ycbcr2rgb(iYCbCr);
% figure(),imshow(irgb),title("RGB image(after 4:2:0 downsample and quantify)");
% imwrite(irgb,'down_and_quan.bmp');

%% 5.zigzagһά��
zigY = zigzag(qdctY);
zigCb = zigzag(qdctCb);
zigCr = zigzag(qdctCr);

%% 6.DCϵ��ʹ��DPCM����
dcY = dpcm(zigY);
dcCb = dpcm(zigCb);
dcCr = dpcm(zigCr);

%% 7.ACϵ��ʹ��RLC����
acY = rlc(zigY);
acCb = rlc(zigCb);
acCr = rlc(zigCr);

%% 8.��DCϵ����ACϵ��Ӧ�û���������
[dcY_comp, dcY_dict] = huffman(dcY);
[dcCb_comp, dcCb_dict] = huffman(dcCb);
[dcCr_comp, dcCr_dict] = huffman(dcCr);
[acY_comp, acY_dict] = huffman(acY);
[acCb_comp, acCb_dict] = huffman(acCb);
[acCr_comp, acCr_dict] = huffman(acCr);

%% 9.��ѹ��������ݱ���
origin_width = uint16(origin_width);
origin_height = uint16(origin_height);
% ����Ҫ����ѹ��ͼ���·��
save('..\img\compressed_image1.mat','dcY_comp','dcCb_comp','dcCr_comp','acY_comp','acCb_comp','acCr_comp','dcY_dict','dcCb_dict','dcCr_dict','acY_dict','acCb_dict','acCr_dict','origin_width','origin_height');

%% �������ܣ���ͼ��ȫΪ����Ϊ8�ı���
function new_img = resize(img)
[m,n,~] = size(img);
new_m = ceil(m/8) * 8; % �������ȡ��8�ı���
new_n = ceil(n/8) * 8;
for i=m+1:new_m
    img(i,:,:)=img(m,:,:);
end
for j=n+1:new_n
    img(:,j,:)=img(:,n,:);
end
new_img = img;
end

%% �������ܣ��Եõ���YCbCr����4:2:0��ɫ�²���
function [y,cb,cr] = downSample(I)
    [imgHeight,imgWidth,~] = size(I);
    y = double(I(:,:,1));                             % y������ѹ��
    cb = double(I(1:2:imgHeight-1,1:2:imgWidth-1,2)); % cb����ÿ��2��2С���鶼ȡ���Ͻ�
    cr = double(I(2:2:imgHeight,2:2:imgWidth,3));     % cr����ÿ��2��2С���鶼ȡ���½�
end

%% �������ܣ���ͼ����8*8��С��Ϊ��λ����dct�任�󷵻�
function [y,cb,cr] = blockdct(imgY,imgCb,imgCr)
    fun = @(block_struct) dct2(block_struct.data);
    y=blockproc(imgY,[8 8],fun);
    cb=blockproc(imgCb,[8 8],fun);
    cr=blockproc(imgCr,[8 8],fun);
end

%% �������ܣ�ͨ�����е����Ⱥ�ɫ���������Ծ����������
function [qy,qcb,qcr] = quantify(y,cb,cr)
    %����������
    LumiTable=[
        16 11 10 16 24 40 51 61 ;
        12 12 14 19 26 58 60 55 ;
        14 13 16 24 40 57 69 56 ;
        14 17 22 29 51 87 80 62 ;
        18 22 37 56 68 109 103 77;
        24 35 55 64 81 104 113 92;
        49 64 78 87 103 121 120 101;
        72 92 95 98 112 100 103 99];
    %ɫ��������
    ChromiTable=[
        17 18 24 47 99 99 99 99 ;
        18 21 26 66 99 99 99 99 ;
        24 26 56 99 99 99 99 99 ;
        47 66 99 99 99 99 99 99 ;
        99 99 99 99 99 99 99 99 ;
        99 99 99 99 99 99 99 99 ;
        99 99 99 99 99 99 99 99 ;
        99 99 99 99 99 99 99 99];    
    
    fun1 = @(block_struct) round(block_struct.data ./ LumiTable);
    fun2 = @(block_struct) round(block_struct.data ./ ChromiTable);
    qy=blockproc(y,[8,8],fun1);
    qcb=blockproc(cb,[8,8],fun2);
    qcr=blockproc(cr,[8,8],fun2);
end

%% �������ܣ�ͨ�����е����Ⱥ�ɫ���������Ծ�����з�����
function [y,cb,cr] = inv_quantify(qy,qcb,qcr)
    %����������
    LumiTable=[
        16 11 10 16 24 40 51 61;
        12 12 14 19 26 58 60 55;
        14 13 16 24 40 57 69 56;
        14 17 22 29 51 87 80 62;
        18 22 37 56 68 109 103 77;
        24 35 55 64 81 104 113 92;
        49 64 78 87 103 121 120 101;
        72 92 95 98 112 100 103 99];
    %ɫ��������
    ChromiTable=[
        17 18 24 47 99 99 99 99 ;
        18 21 26 66 99 99 99 99 ;
        24 26 56 99 99 99 99 99 ;
        47 66 99 99 99 99 99 99 ;
        99 99 99 99 99 99 99 99 ;
        99 99 99 99 99 99 99 99 ;
        99 99 99 99 99 99 99 99 ;
        99 99 99 99 99 99 99 99];    
    
    fun1 = @(block_struct) block_struct.data .* LumiTable;
    fun2 = @(block_struct) block_struct.data .* ChromiTable;
    y = blockproc(qy,[8,8],fun1);
    cb = blockproc(qcb,[8,8],fun2);
    cr = blockproc(qcr,[8,8],fun2);
end

%% �������ܣ�ͨ��zigzag����8��8���󣬲���һ��1��64������
function zigx = block_zigzag(x)
    zigzag_table=[
        1 2 9 17 10 3 4 11;
        18 25 33 26 19 12 5 6;
        13 20 27 34 41 49 42 35; 
        28 21 14 7 8 15 22 29;
        36 43 50 57 58 51 44 37;
        30 23 16 24 31 38 45 52;
        59 60 53 46 39 32 40 47;
        54 61 62 55 48 56 63 64];
    
    v = reshape(x',1,64); % ������8��8�����Ϊ1x64������
    vtable = reshape(zigzag_table',1,64);
    zigx = v(vtable); % ͨ�����ķ�ʽģ��zigzagɨ��
end

%% �������ܣ����������ֳ�8��8��С�飬�ֱ����zigzag����
function zigx = zigzag(x)
    fun = @(block_struct) block_zigzag(block_struct.data);
    tzigx = blockproc(x,[8,8],fun);
    [a,b] = size(tzigx);
    zigx = reshape(tzigx',64,a*b/64);   % ��zigzag�����ľ����ʽ����Ϊ64��n�����ڽ�������DCϵ����ACϵ���ֱ���
end

%% �������ܣ���DCϵ������DPCM����
function en = dpcm(x)
    f = x(1,:);
    [~,cnt] = size(f);
    f_pre = zeros(1,cnt);
    f_rec = zeros(1,cnt);
    e = zeros(1,cnt);
    en = zeros(1,cnt);
    f_pre(1) = f(1); % Ԥ���źŵ�ǰ������ʼ��Ϊԭʼ�źŵĵ�һ���ź�
    f_pre(2) = f(1);
    f_rec(1) = f(1); % �ع��źŵĵ�һ��ֵҲ��ʼ��Ϊԭʼ�źŵĵ�һ���ź�
    en(1) = f(1); % ԭ����en(1)Ӧ������0�������︳ֵΪf(1)��������������enʱ�Ͱ�����f(1)��ֵ�Լ������Ĳ�ֵ�����ڽ���
    for i=2:cnt
        if(i ~= 2)
            f_pre(i) = (f_rec(i-1) + f_rec(i-2))/2;
            %f_pre(i) = (f(i-1) + f(i-2))/2;
        end
        e(i) = f(i) - f_pre(i);
        %en(i) = 16 * floor((255 + e(i))/16) - 256 + 8; %�˴�ѡ��ͬ��ʽ�ӿ��Ե�����DCϵ���������̶�
        %en(i) = 8 * floor((255 + e(i))/8) - 256 + 4;
        %en(i) = 4 * floor((255 + e(i))/4) - 256 + 2;
        en(i) = 2 * floor((255 + e(i))/2) - 256 + 1;    
        %en(i) = e(i);
        f_rec(i) = f_pre(i) + en(i);        
    end
    
end

%% �������ܣ���ACϵ������RLC����
function rlc_table = rlc(x)
    ac = x(2:64,:);
    [m,n] = size(ac);
    cnt = m * n;
    zero_cnt = 0;
    rlc_table = [];
    for i=1:cnt
        %if ac(i) == 0  %�˴�ѡ��ͬ��ʽ�ӿ��Ե�����ACϵ���������̶�
        if ac(i) >= -1 && ac(i) <= 1
        %if ac(i) >= -2 && ac(i) <= 2
        %if ac(i) >= -4 && ac(i) <= 4
            zero_cnt = zero_cnt + 1;
        else
            rlc_table = [rlc_table;[zero_cnt,ac(i)]];
            zero_cnt = 0;
        end
    end
    rlc_table = [rlc_table;[0,0]];  % ���ĩ��Ϊ[0,0]
end

%% �������ܣ��Դ���Ĳ�������huffman���벢�������ֺ��ֵ�
function [comp,dict] = huffman(x)
    [m,n] = size(x);
    xx = reshape(x, 1, m*n);     %������ת��Ϊ������
    table = tabulate(xx(:));     %ͳ�������и����ַ����ֵĸ���
    symbols = table(:,1);        %�ַ����浽symbols��
    p = table(:,3) ./ 100;       %��Ӧ�ĸ��ʱ��浽p��
    dict = huffmandict(symbols,p);  %����huffmandict���������ֵ�
    comp = huffmanenco(xx,dict);    %����huffmanenco�����������е��ֵ佫�������
    comp = uint8(comp);          %Ĭ�ϵ�huffmanenco�õ���comp����double�洢�ģ������Ϊuint8��ʡ�ռ�
end