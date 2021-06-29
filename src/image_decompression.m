%% 1.��ȡѹ���������
clear;
load('..\img\compressed_image1.mat');
origin_width = double(origin_width);
origin_height = double(origin_height);
resize_width = ceil(origin_width/8) * 8;
resize_height = ceil(origin_height/8) * 8;

%% 2.����������õ�DPCM������DCϵ����RLC������ACϵ��
dcY = myhuffmandeco(dcY_comp, dcY_dict);
dcCb = myhuffmandeco(dcCb_comp, dcCb_dict);
dcCr = myhuffmandeco(dcCr_comp, dcCr_dict);
acY = myhuffmandeco(acY_comp, acY_dict);
acCb = myhuffmandeco(acCb_comp, acCb_dict);
acCr = myhuffmandeco(acCr_comp, acCr_dict);

%% 3.DPCM����õ�DCϵ��
dcY_rec = dpcm_decode(dcY);
dcCb_rec = dpcm_decode(dcCb);
dcCr_rec = dpcm_decode(dcCr);

%% 4.RLC����õ�ACϵ��
[~,col_cnt] = size(dcY_rec);
acY_rec = rlc_decode(acY,col_cnt);
acCb_rec = rlc_decode(acCb,col_cnt/4);
acCr_rec = rlc_decode(acCr,col_cnt/4);

%% 5.ACϵ����DCϵ��������ϳ������ľ���
zigY = [dcY_rec;acY_rec];
zigCb = [dcCb_rec;acCb_rec];
zigCr = [dcCr_rec;acCr_rec];

%% 6.��zigzag�任
qdctY = inv_zigzag(zigY,resize_width);
qdctCb = inv_zigzag(zigCb,resize_width/2);
qdctCr = inv_zigzag(zigCr,resize_width/2);

%% 7.������������з�����
[iqdctY,iqdctCb,iqdctCr] = inv_quantify(qdctY,qdctCb,qdctCr);

%% 8.��dct�任
[iy,icb,icr] = inv_blockdct(iqdctY,iqdctCb,iqdctCr);

%% 9.������ɫ�²�����Ľ����������YCbCrͼ��
iYCbCr = regenerate_Ycbcr(iy,icb,icr);

%% 10.YCbCrͼ��ת��ΪRGBͼ��
irgb = ycbcr2rgb(iYCbCr);
irgb_origin = irgb(1:origin_height,1:origin_width,:);
figure(),imshow(irgb_origin),title("reconstructed image");
imwrite(irgb_origin,'..\img\reconstructed_1.bmp');  % ����Ҫ�����ع�ͼ���·��

%% �������ܣ�huffman����
function sig = myhuffmandeco(comp,dict)
    comp = double(comp);    %���½�comp��ԭ��double���ͣ������޷�����huffmandeco����
    sig = huffmandeco(comp,dict);
end

%% �������ܣ���DCϵ������DPCM����
function f_rec = dpcm_decode(en)
    [~,cnt] = size(en);
    f_pre = zeros(1,cnt);
    f_rec = zeros(1,cnt);
    f_pre(1) = en(1); %Ԥ���źŵ�ǰ������ʼ��Ϊԭʼ�źŵĵ�һ���ź�
    f_pre(2) = en(1);
    f_rec(1) = en(1); %�ع��źŵĵ�һ��ֵҲ��ʼ��Ϊԭʼ�źŵĵ�һ���ź�
    for i=2:cnt
        if(i ~= 2)
            f_pre(i) = (f_rec(i-1) + f_rec(i-2))/2;
        end
        f_rec(i) = f_pre(i) + en(i);        
    end
    f_rec = double(uint8(f_rec));   %ȡ��֮������ת��Ϊdouble����
end

%% �������ܣ���RLC������ACϵ�����н���
function out = rlc_decode(in,col_cnt)
    [~,cnt] = size(in);
    rlc_table = reshape(in,cnt/2,2);    %�����뻹ԭΪ���е�rlc�����ʽ
    ac_vec = zeros(1,63 * col_cnt);
    j = 1;
    for i=1:cnt/2
        if(rlc_table(i,1) == 0)         %ĳ�еĵ�һ����Ϊ0����ֱ�ӽ���һ��������ac_vec
            ac_vec(j) = rlc_table(i,2);
            j = j + 1;
        else                            %ĳ�еĵ�һ������Ϊ0�����������Ϊ0�ĸ�������ac_vec�����Ӧ������0
            for k=1:rlc_table(i,1)
                ac_vec(j) = 0;
                j = j + 1;
            end
            ac_vec(j) = rlc_table(i,2); %Ȼ�󽫸��еĺ�һ��������ac_vec
            j = j + 1;
        end
    end
    out = reshape(ac_vec,63,col_cnt);   %���µ��������ʽΪ63�е�ACϵ�������ں�����DCϵ��ƴ��
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
    zigx = reshape(tzigx',64,a*b/64);   % ��zigzag�����ľ����ʽ����Ϊn��64�����ڽ�������DCϵ����ACϵ���ֱ���
end

%% �������ܣ���һ��64��1����������zigzag�任��ԭΪ8��8�ľ���
function invzigx = block_inv_zigzag(x)
    zigzag_table=[
        1 2 9 17 10 3 4 11;
        18 25 33 26 19 12 5 6;
        13 20 27 34 41 49 42 35; 
        28 21 14 7 8 15 22 29;
        36 43 50 57 58 51 44 37;
        30 23 16 24 31 38 45 52;
        59 60 53 46 39 32 40 47;
        54 61 62 55 48 56 63 64];
    
    vtable = reshape(zigzag_table',1,64);   
    invzigx = zeros(8,8);
    for i=1:64
        invzigx(vtable(i)) = x(i);  % ͨ�����ķ�ʽ��������zigzagɨ��
    end
    invzigx = invzigx';
end

%% �������ܣ�����������ÿһ�зֱ������zigzag����
function invzigx = inv_zigzag(x,resize_width)
    tzigx = reshape(x,resize_width*8,[]);
    tzigx = tzigx';
    fun = @(block_struct) block_inv_zigzag(block_struct.data);
    invzigx = blockproc(tzigx,[1,64],fun);
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

%% �������ܣ���ͼ����8*8��С��Ϊ��λ������dct�任�󷵻�
function [y,cb,cr] = inv_blockdct(dcty,dctcb,dctcr)
    fun = @(block_struct) idct2(block_struct.data);
    y=blockproc(dcty,[8 8],fun);
    cb=blockproc(dctcb,[8 8],fun);
    cr=blockproc(dctcr,[8 8],fun);
end

%% �������ܣ�������ɫ�²�����Ľ����������ͼ��
function down_imgYCbCr = regenerate_Ycbcr(imgY,imgCb,imgCr)
    [YH,YL] = size(imgY);
    [CbH,CbL] = size(imgCb);
    y = uint8(imgY);
    cb = zeros(YH,YL);
    cr = zeros(YH,YL);
    for i=1:CbH
        for j=1:CbL
            [cb(2*i,2*j),cb(2*i-1,2*j),cb(2*i,2*j-1),cb(2*i-1,2*j-1)] = deal(imgCb(i,j)); %ÿһ��ֵ��Ҫ���һ��2��2��С��
            [cr(2*i,2*j),cr(2*i-1,2*j),cr(2*i,2*j-1),cr(2*i-1,2*j-1)] = deal(imgCr(i,j));
        end
    end
    cb = uint8(cb);
    cr = uint8(cr);
    down_imgYCbCr = cat(3,y,cb,cr);
end
