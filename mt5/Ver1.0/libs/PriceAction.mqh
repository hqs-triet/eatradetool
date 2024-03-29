#include  "ExpertWrapper.mqh"
#include  "Common.mqh"
//+------------------------------------------------------------------+
// Lấy tỉ lệ % bóng phía trên so với chiều cao của cả nến
//+------------------------------------------------------------------+
double CandleTailUpPercent(int idx, AllSeriesInfo &priceInfo)
{
    double h = priceInfo.high(idx);
    double l = priceInfo.low(idx);
    double compare = priceInfo.close(idx);
    
    if(IsCandleDown(idx, priceInfo))
    {
        compare = priceInfo.open(idx);
    }
    
    if(h - l > 0)
        return (h - compare) * 100 / (h - l);
    return 0;
}

//+------------------------------------------------------------------+
// Lấy tỉ lệ % bóng phía dưới so với chiều cao của cả nến
//+------------------------------------------------------------------+
double CandleTailDownPercent(int idx, AllSeriesInfo &priceInfo)
{
    double h = priceInfo.high(idx);
    double l = priceInfo.low(idx);
    double compare = priceInfo.open(idx);
    
    if(IsCandleDown(idx, priceInfo))
    {
        compare = priceInfo.close(idx);
    }
    
    if(h - l > 0)
        return (compare - l) * 100 / (h - l);
    return 0;
}

//+------------------------------------------------------------------+
// Lấy tỉ lệ % thân nến so với chiều cao của cả nến
//+------------------------------------------------------------------+
double CandleBodyPercent(int idx, AllSeriesInfo &priceInfo)
{  
    double h = priceInfo.high(idx);
    double l = priceInfo.low(idx);
    
    if(h - l > 0)
    {
        return (MathAbs(priceInfo.close(idx) - priceInfo.open(idx)) * 100) / (h - l);
    }
    return 0;
}

//+------------------------------------------------------------------+
// Kiểm tra nến có phải nến búa không
// Căn cứ:
// . Tính tỉ lệ bóng nến trên dưới: [bóng dưới] lớn hơn nhiều so với [bóng trên]
// . Thân nến chiếm từ 10~35% so với nến
//+------------------------------------------------------------------+
bool IsHammerBar(int idx, AllSeriesInfo &priceInfo)
{
    return (CandleBodyPercent(idx, priceInfo) <= 35 && CandleBodyPercent(idx, priceInfo) >= 10
            && CandleTailDownPercent(idx, priceInfo) >= 55
            && CandleTailUpPercent(idx, priceInfo) <= 5);
}

//+------------------------------------------------------------------+
// Kiểm tra nến có phải nến búa ngược không
// Căn cứ:
// . Tính tỉ lệ bóng nến trên dưới: [bóng dưới] nhỏ hơn nhiều so với [bóng trên]
// . Thân nến chiếm từ 10~35% so với nến
//+------------------------------------------------------------------+
bool IsReverseHammerBar(int idx, AllSeriesInfo &priceInfo)
{
    return (CandleBodyPercent(idx, priceInfo) <= 35 && CandleBodyPercent(idx, priceInfo) >= 10
            && CandleTailUpPercent(idx, priceInfo) >= 55
            && CandleTailDownPercent(idx, priceInfo) <= 5);
}

//+------------------------------------------------------------------+
// Kiểm tra nến có phải nến dạng pinbar (dạng nhỏ)
// Căn cứ:
// . Thân nến chiếm 5%~10% so với nến
//+------------------------------------------------------------------+
bool IsPinBarSmall(int idx, AllSeriesInfo &priceInfo)
{
    return (CandleBodyPercent(idx, priceInfo) < 10 && CandleBodyPercent(idx, priceInfo) >= 5);
}

//+------------------------------------------------------------------+
// Kiểm tra nến có phải nến pinbar (dạng lớn)
// Căn cứ:
// . Thân nến lớn hơn 10% và nhỏ hơn 35%
//+------------------------------------------------------------------+
bool IsPinBarBig(int idx, AllSeriesInfo &priceInfo)
{
    return (CandleBodyPercent(idx, priceInfo) >= 10 && CandleBodyPercent(idx, priceInfo) <= 35);
}

//+------------------------------------------------------------------+
// Kiểm tra nến có phải nến pinbar giảm mạnh
// Căn cứ:
// . Là pinbar dạng nhỏ
// . Bóng nến (phía trên) chiếm từ 60% so với nến
//+------------------------------------------------------------------+
bool IsBearishPinBar(int idx, AllSeriesInfo &priceInfo)
{
    return (IsPinBarSmall(idx, priceInfo) && CandleTailUpPercent(idx, priceInfo) >= 60);
}
//+------------------------------------------------------------------+
// Kiểm tra nến có phải nến pinbar tăng mạnh
// Căn cứ:
// . Là pinbar dạng nhỏ
// . Bóng nến (phía dưới) chiếm từ 60% so với nến
//+------------------------------------------------------------------+
bool IsBullishPinBar(int idx, AllSeriesInfo &priceInfo)
{
    return (IsPinBarSmall(idx, priceInfo) && CandleTailDownPercent(idx, priceInfo) >= 60);
}
//+------------------------------------------------------------------+
// Kiểm tra nến có phải nến sao băng
// Căn cứ:
// . Là pinbar dạng nhỏ
// . Bóng nến (phía trên) chiếm từ 60% so với nến
// . Bóng nến (phía dưới) chiếm từ 5~10% so với nến
//+------------------------------------------------------------------+
bool IsShootingStarBar(int idx, AllSeriesInfo &priceInfo)
{
    return (IsPinBarSmall(idx, priceInfo) 
            && CandleTailUpPercent(idx, priceInfo) >= 60 
            && CandleTailDownPercent(idx, priceInfo) <= 10
            && CandleTailDownPercent(idx, priceInfo) >= 5);
}

//+------------------------------------------------------------------+
// Kiểm tra nến có phải nến inside (nến nằm lọt lòng so với nến trước)
// Căn cứ:
// . Giá cao nhất và giá thấp nhất so với nến trước đó
//+------------------------------------------------------------------+
bool IsInsideBar(int idx, AllSeriesInfo &priceInfo)
{
    return (priceInfo.high(idx) < priceInfo.high(idx + 1) && priceInfo.low(idx) > priceInfo.low(idx + 1));
}

//+------------------------------------------------------------------+
// Kiểm tra nến có phải nến nhấn chìm
// Căn cứ:
// . Giá cao nhất và giá thấp nhất so với nến trước đó
//+------------------------------------------------------------------+
bool IsEngulfing(int idx, AllSeriesInfo &priceInfo)
{
    return (priceInfo.high(idx) > priceInfo.high(idx + 1) && priceInfo.low(idx) < priceInfo.low(idx + 1) );
}

//+------------------------------------------------------------------+
// Kiểm tra nến có phải nến nhấn chìm giảm
// Căn cứ:
// . Giá cao nhất và giá thấp nhất so với nến trước đó
//+------------------------------------------------------------------+
bool IsBearishEngulfing(int idx, AllSeriesInfo &priceInfo)
{
    return (IsCandleDown(idx, priceInfo) && IsEngulfing(idx, priceInfo));
}

//+------------------------------------------------------------------+
// Kiểm tra nến có phải nến nhấn chìm tăng
// Căn cứ:
// . Giá cao nhất và giá thấp nhất so với nến trước đó
//+------------------------------------------------------------------+
bool IsBullishEngulfing(int idx, AllSeriesInfo &priceInfo)
{
    return (IsCandleUp(idx, priceInfo) && IsEngulfing(idx, priceInfo));
}

//+------------------------------------------------------------------+
// Kiểm tra nến có phải nến chuồng chuồng
// Căn cứ:
// . Thân nến chiếm nhỏ hơn 5% với với nến
//+------------------------------------------------------------------+
bool IsDojiCandle(int idx, AllSeriesInfo &priceInfo)
{
    return (CandleBodyPercent(idx, priceInfo) < 5);
}

//+------------------------------------------------------------------+
// Kiểm tra nến hiện tại và nến trước đó có phải là nến dạng chuồng chuồng
// Căn cứ:
// . Thân nến chiếm nhỏ hơn 5% với với nến
//+------------------------------------------------------------------+
bool IsDoubleDojiCandle(int idx, AllSeriesInfo &priceInfo)
{
    return (IsDojiCandle(idx, priceInfo) && IsDojiCandle(idx+1, priceInfo));
}
//+------------------------------------------------------------------+
// Kiểm tra nến hiện tại và 2 nến trước đó có phải là nến dạng chuồng chuồng
// Căn cứ:
// . Thân nến chiếm nhỏ hơn 5% với với nến
//+------------------------------------------------------------------+
bool IsTripleDojiCandle(int idx, AllSeriesInfo &priceInfo)
{
    return (IsDojiCandle(idx, priceInfo) && IsDojiCandle(idx+1, priceInfo) && IsDojiCandle(idx+2, priceInfo));
}
