image_compression.m       为压缩程序的源代码
image_decompression.m   为解压程序的源代码

需要使用MATLAB打开，使用时先运行image_compression.m得到压缩后的结果，
再运行image_decompression.m读取压缩后的数据并解压。
调整imread函数和save函数的参数来更换要压缩的图像和压缩后数据的存储路径
调整load函数和imwrite函数的参数来更换要读取的压缩数据和重构图像的存储路径