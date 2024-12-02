#property description "Công cụ trade theo chiến thuật Double In A Day"
#property copyright "ForexProEA"
#property link "https://www.facebook.com/groups/forexproea/"
#property version   "1.1"

#resource "\\Indicators\\ForexProEA_FanSignal_PublishedMQL5.ex5"
#resource "\\Indicators\\ressup.ex5"
#include <trade/trade.mqh>
#include <expert/expertbase.mqh>
#include  "libs\ExpertWrapper.mqh"
#include  "libs\Common.mqh"
#include  "libs\Algorithm\GuiTrade_v1.mqh"

// ===================================================================
// Tham số đầu vào của EA [start]
// ===================================================================
// Mã số định danh cho EA (để phân biệt với các EA khác)
input ulong InpMagicNumber = 10001274;  // Magic number
input string InpCommentPlus = "fx";     // Prefix for comment of an order
input bool InpUseTradeToolbox = false;  // Show the toolbox on GUI
input ENUM_TIMEFRAMES InpTf = PERIOD_CURRENT;

input group "Setting: Auto trade ======"
input bool InpAutoTrade = false;    // Auto trade?
input int  InpMaxSpread = 50;       // Limit spread
input double InpVol = 0.02;         // The volume by lot
input double InpVolPercent = 1;   // Or by percent of account (prior, 0: not use)
input double InpRR = 8;             // RR
input int    InpSLBuffPoints = 0;  // The buffer for Entry/SL
input int    InpMaxSLPoint = 320;   // The max SL in points
//input int    InpMaxSLPointCalc = 400;   // The SL in runtime (if over EA stops!)
input int    InpMinSL = 320;   // The min SL in points
input int    InpFanCrossConsolidate = 2;    // The number of fan cross consolidate
input string InpFan = "4;8;12;16;20;24;28;32;36;40;44;48;52;56;60;64;68;72;76;80";   // Fan EMA list
//input int InpZone = 330;                    // Res-Sup: Zone (in points)
//input int InpLookbackPoint = 50;            // Res-Sup: Look back top/bottom points

input group "Setting: Double In A Day ======"
input bool   InpUseDoubleInDay = false;
#include  "libs\\DoubleInDay_v1.mqh"
//#include  "libs\\Hedge_1.mqh"

// ===================================================================
// Tham số đầu vào của EA [ end ]
// ===================================================================


// ===================================================================
// Khai báo các đối tượng cục bộ [start]
// ===================================================================
// Sử dụng đối tượng để thao tác mở lệnh trong EA
CTrade        m_trader;
// Đối tượng truy xuất thông tin giá
AllSeriesInfo m_infoCurrency;

// Thông tin chung
string m_symbolCurrency;    // Cặp tiền tệ đang trade
ENUM_TIMEFRAMES m_tf;       // Khung thời gian đang trade
int m_prevCalculated;       // Lưu số lượng nến trước đó, dùng để tính số lượng nến phát sinh
int m_limit;                // Lưu số lượng nến phát sinh động

CDoubleInDay *m_doubleInDay;
CGuiTrade *m_guiTrade;

int m_fanHandler, m_ressupHandler, m_emaLongHandler, m_osmaHandler;
double m_upBuff[], m_downBuff[], m_lastBuff[], m_emaLongBuff[], m_ema6Buff[], m_osmaBuff[],
       m_resUpperBuffer[], m_resLowerBuffer[], m_supUpperBuffer[], m_supLowerBuffer[];

//CHedge *m_hedge;
int triggerCount = 5;
int TRIGGER_COUNT = 5;
// ===================================================================
// Khai báo các đối tượng cục bộ [ end ]
// ===================================================================


//+------------------------------------------------------------------+
// Khởi tạo các thông số cho chiến thuật
//+------------------------------------------------------------------+
int Init(string symbol, ENUM_TIMEFRAMES tf)
{
    
    // Lưu các tham số khởi tạo
    m_symbolCurrency = symbol;
    m_tf = tf;
    
    // Khởi tạo đối tượng thao tác mở lệnh
    m_trader.SetExpertMagicNumber(InpMagicNumber); // Số định danh
    m_trader.SetMarginMode();
    m_trader.SetTypeFillingBySymbol(m_symbolCurrency);
    
    // Khởi tạo đối tượng thao tác giá
    m_infoCurrency.init(m_symbolCurrency, m_tf);
    
    if(InpUseTradeToolbox)
    {
        // Khởi tạo công cụ thiết lập SL, TP, Entry trên giao diện
        m_guiTrade = new CGuiTrade();
        TAction actSell = OnSellCustom;
        TAction actBuy = OnBuyCustom;
        TAction onUseGUI = OnUseGUI;
        TAction onUseStopLimit = OnUseStopLimit;
        m_guiTrade.OnSell(actSell);
        m_guiTrade.OnBuy(actBuy);
        m_guiTrade.SetActionUseGUI(onUseGUI);
        m_guiTrade.SetActionUseStopLimit(onUseStopLimit);
        m_guiTrade.Init(m_symbolCurrency, m_tf, m_trader, m_infoCurrency);
    }
    if(InpUseDoubleInDay)
    {
        m_doubleInDay = new CDoubleInDay();
        bool isInitOK = m_doubleInDay.Init(m_symbolCurrency, m_tf, m_trader, 
                                            m_infoCurrency, InpMagicNumber);
        if(!isInitOK) return INIT_FAILED;
        m_doubleInDay.Setting(InpCommentPlus);
    }
    
    if(InpAutoTrade)
    {
        InitSeries(m_upBuff);
        InitSeries(m_downBuff);
        InitSeries(m_lastBuff);
        InitSeries(m_ema6Buff);
        InitSeries(m_osmaBuff);
        InitSeries(m_emaLongBuff);
        InitSeries(m_resUpperBuffer);
        InitSeries(m_resLowerBuffer);
        InitSeries(m_supUpperBuffer);
        InitSeries(m_supLowerBuffer);
        m_fanHandler = iCustom(m_symbolCurrency, m_tf, 
                               "::Indicators\\ForexProEA_FanSignal_PublishedMQL5.ex5",
                               InpFan, MODE_EMA
                               );
        m_osmaHandler = iOsMA(m_symbolCurrency, m_tf, 12, 26, 9, PRICE_CLOSE);
        
        //m_ressupHandler = iCustom(m_symbolCurrency, m_tf, 
        //                       "::Indicators\\ressup.ex5",
        //                       true, false, 8, InpZone, false, InpLookbackPoint, 
        //                       -1, -1, -1,
        //                       false, false, 5
        //                   );
        //iCustom(m_symbolCurrency, PERIOD_H4, 
        //       "::Indicators\\ressup.ex5",
        //       true, false, 8, InpZone, false, InpLookbackPoint, 
        //       -1, -1, -1,
        //       false, false, 5
        //   );
        //if(m_ressupHandler <= 0)
        //{
        //    Print("ERROR: cannot init ressup indicator ========================");
        //    return INIT_FAILED;
        //}
        
        //m_emaLongHandler = iMA(m_symbolCurrency, m_tf, 200, 0, MODE_EMA, PRICE_CLOSE);
    }
    
//    if(InpUseHedge)
//    {
//        m_hedge = new CHedge();
//        m_hedge.InitHedge(m_symbolCurrency, m_tf, m_trader, m_infoCurrency, InpMagicNumber);
//        m_hedge.MaxWireHedge(InpHedgeMaxWire);
//        m_hedge.RR(InpHedgeRiskReward);
//        m_hedge.LotChainRatio(InpHedgeLotsChainRatio);
//        m_hedge.ExpectProfit(InpHedgeExpectProfit);
//        m_hedge.SetAppendComment(InpCommentPlus);
//        m_hedge.InternalComment("hedge");
//        
//    }

    //iMA(m_symbolCurrency, m_tf, 50, 0, MODE_EMA, PRICE_CLOSE);
    //iRSI(m_symbolCurrency, PERIOD_CURRENT, 14, PRICE_CLOSE);
    //iRSI(m_symbolCurrency, PERIOD_H4, 14, PRICE_CLOSE);
    //iRSI(m_symbolCurrency, m_tf, 14, PRICE_CLOSE);
    
    
    return INIT_SUCCEEDED;
}
bool waitForTurn(bool newCandle)
{
    if(!newCandle)
    {
        triggerCount -= 1;
        if(triggerCount > 0) 
            return false;
        else
            triggerCount = TRIGGER_COUNT;
    }
    else
        triggerCount = TRIGGER_COUNT;
    
    return true;
}
//+------------------------------------------------------------------+
// Xử lý chính của chiến thuật
//+------------------------------------------------------------------+
void Process()
{
    // Xử lý các tác vụ chung
    bool newCandle = ProcessCommon();
    if(!waitForTurn(newCandle)) return;
    
    ReadIndicatorData(newCandle);
    
    // ===================================================================
    // Xử lý chính giao dịch [start]
    // ===================================================================
    if(InpUseDoubleInDay)
    {
        //bool existTopup = m_doubleInDay.ExistTopup();
        //if(existTopup)
        //{
        //    if(m_hedge != NULL)
        //    {
        //        m_hedge.Disable(true);
        //    }
        //}
        m_doubleInDay.Process(m_limit);
        
    }
    
    // Gọi xử lý của đối tượng hedge
    //if(InpUseHedge)
    //{
    //    bool existWire = m_hedge.ExistWire();
    //    if(existWire)
    //    {
    //        if(m_doubleInDay != NULL)
    //        {
    //            m_doubleInDay.Disable(true);
    //        }
    //    }
    //    m_hedge.Process(m_limit);
    //}
    
    if(InpAutoTrade && newCandle)
    {
        ulong outTickets[];
        
        int len = SearchActiveOpenPosition(m_symbolCurrency, InpMagicNumber, InpCommentPlus, true, true, outTickets);
        if(len == 0)
        {
            len = GetPendingOrdersByType(m_symbolCurrency, InpMagicNumber, ORDER_TYPE_BUY_LIMIT, InpCommentPlus)
                  + GetPendingOrdersByType(m_symbolCurrency, InpMagicNumber, ORDER_TYPE_SELL_LIMIT, InpCommentPlus);
            if(len == 0)
            {
                ProcessSell(newCandle);
                ProcessBuy(newCandle);
            }
        }
    }
    // ===================================================================
    // Xử lý chính giao dịch [ end ]
    // ===================================================================
}

void ProcessSell(bool newCandle)
{
    bool canMakeOrder = false;


    int countUp = 0;
    int countDown = 0;
    int crossNumCalc = InpFanCrossConsolidate - 1;
    if(crossNumCalc <= 0)
        crossNumCalc = 1;
    for(int i = 1; i < 50*crossNumCalc; i++)
    {
        if(m_upBuff[i] > 0)
            countUp++;
        if(m_downBuff[i] > 0)
            countDown++;
    }
    canMakeOrder = (countDown >= InpFanCrossConsolidate);// || (countDown == 1 && countUp > 0);
    //canMakeOrder = canMakeOrder && m_downBuff[1] > 0;
    canMakeOrder = canMakeOrder && m_infoCurrency.spread(0) <= InpMaxSLPoint;
    //canMakeOrder = canMakeOrder 
    //               && m_infoCurrency.high(1) > m_ema6Buff[1]
    //               && m_infoCurrency.open(1) < m_ema6Buff[1]
    //               && m_infoCurrency.close(1) < m_ema6Buff[1];
    canMakeOrder = canMakeOrder && (m_osmaBuff[1] > 0 && m_osmaBuff[2] > 0 && m_osmaBuff[1] < m_osmaBuff[2]);
    canMakeOrder = canMakeOrder && (m_infoCurrency.high(1) < m_lastBuff[1]);
    
    //canMakeOrder = canMakeOrder && m_resLowerBuffer[1] > 0 && m_resUpperBuffer[1] > 0;
    if(canMakeOrder)
    {
        // Open sell
        double entry = GetMaxPriceRange(m_infoCurrency, 1, 10, true) + PointsToPriceShift(m_symbolCurrency, InpSLBuffPoints);
        if( entry > m_lastBuff[1]) return;
        double sl = m_lastBuff[1] + PointsToPriceShift(m_symbolCurrency, InpSLBuffPoints);
        
        int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(sl - entry));
        //if (slPoints > InpMaxSLPointCalc)
        //    return;
        if (slPoints > InpMaxSLPoint)
        {
            slPoints = InpMaxSLPoint;
            sl = entry + PointsToPriceShift(m_symbolCurrency, slPoints);
        }
        if(slPoints < InpMinSL)
        {
            slPoints = InpMinSL;
            sl = entry + PointsToPriceShift(m_symbolCurrency, slPoints);
        }
        int tpPoints = slPoints * InpRR;
        double tp = entry - PointsToPriceShift(m_symbolCurrency, tpPoints);
        string comment = InpCommentPlus;
        comment += ";01;" + slPoints + ";" + tpPoints;
        double vol = InpVol;
        if( InpVolPercent > 0)
        {
            vol = PointsToLots(m_symbolCurrency, InpVolPercent, slPoints);
        }
        datetime expiredDate = TimeCurrent();
        TimeAdd(expiredDate, 12, 0, 0);
        if(m_trader.SellLimit(vol, entry, m_symbolCurrency, sl, tp, ORDER_TIME_SPECIFIED, expiredDate, comment))
        {
            //if(InpUseHedge && m_hedge != NULL)
            //    m_hedge.Disable(false);
            if(InpUseDoubleInDay && m_doubleInDay != NULL)
                m_doubleInDay.Disable(false);
        }
    }
//    if(canMakeOrder)
//    {
//        // Open sell
//        double entry = m_infoCurrency.bid();
//        double sl = m_lastBuff[1] + PointsToPriceShift(m_symbolCurrency, InpSLBuffPoints);
//        
//        int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(sl - entry));
//        //if (slPoints > InpMaxSLPointCalc)
//        //    return;
//        if (slPoints > InpMaxSLPoint)
//        {
//            slPoints = InpMaxSLPoint;
//            sl = entry + PointsToPriceShift(m_symbolCurrency, slPoints);
//        }
//        if(slPoints < InpMinSL)
//        {
//            slPoints = InpMinSL;
//            sl = entry + PointsToPriceShift(m_symbolCurrency, slPoints);
//        }
//        int tpPoints = slPoints * InpRR;
//        double tp = entry - PointsToPriceShift(m_symbolCurrency, tpPoints);
//        string comment = InpCommentPlus;
//        comment += ";01;" + slPoints + ";" + tpPoints;
//        double vol = InpVol;
//        if( InpVolPercent > 0)
//        {
//            vol = PointsToLots(m_symbolCurrency, InpVolPercent, slPoints);
//        }
//        if(m_trader.Sell(vol, m_symbolCurrency, 0, sl, tp, comment))
//        {
//            //if(InpUseHedge && m_hedge != NULL)
//            //    m_hedge.Disable(false);
//            if(InpUseDoubleInDay && m_doubleInDay != NULL)
//                m_doubleInDay.Disable(false);
//        }
//    }
    
}
void ProcessBuy(bool newCandle)
{
    bool canMakeOrder = false;
    
    int countUp = 0;
    int countDown = 0;
    int crossNumCalc = InpFanCrossConsolidate - 1;
    if(crossNumCalc <= 0)
        crossNumCalc = 1;
    for(int i = 1; i < 50*crossNumCalc; i++)
    {
        if(m_upBuff[i] > 0)
            countUp++;
        if(m_downBuff[i] > 0)
            countDown++;
    }
    canMakeOrder = (countUp >= InpFanCrossConsolidate);// || (countUp == 1 && countDown > 0);
    //canMakeOrder = canMakeOrder && m_upBuff[1] > 0;
    canMakeOrder = canMakeOrder && m_infoCurrency.spread(0) <= InpMaxSLPoint;
    //canMakeOrder = canMakeOrder 
    //               && m_infoCurrency.low(1) < m_ema6Buff[1]
    //               && m_infoCurrency.open(1) > m_ema6Buff[1]
    //               && m_infoCurrency.close(1) > m_ema6Buff[1];
    canMakeOrder = canMakeOrder && (m_osmaBuff[1] < 0 && m_osmaBuff[2] < 0 && m_osmaBuff[1] > m_osmaBuff[2]);
    canMakeOrder = canMakeOrder && (m_infoCurrency.low(1) > m_lastBuff[1]);
    
    //canMakeOrder = canMakeOrder && m_supLowerBuffer[1] > 0 && m_supUpperBuffer[1] > 0;
    
    if(canMakeOrder)
    {
        // Open buy
        double entry = GetMinPriceRange(m_infoCurrency, 1, 10, true) - PointsToPriceShift(m_symbolCurrency, InpSLBuffPoints);
        if( entry < m_lastBuff[1]) return;
        double sl = m_lastBuff[1] - PointsToPriceShift(m_symbolCurrency, InpSLBuffPoints);

        int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(sl - entry));
        //if (slPoints > InpMaxSLPointCalc)
        //    return;
            
        if (slPoints > InpMaxSLPoint)
        {
            slPoints = InpMaxSLPoint;
            sl = entry - PointsToPriceShift(m_symbolCurrency, slPoints);
        }
        if(slPoints < InpMinSL)
        {
            slPoints = InpMinSL;
            sl = entry - PointsToPriceShift(m_symbolCurrency, slPoints);
        }
        int tpPoints = slPoints * InpRR;
        double tp = entry + PointsToPriceShift(m_symbolCurrency, tpPoints);
        string comment = InpCommentPlus;
        comment += ";01;" + slPoints + ";" + tpPoints;
        double vol = InpVol;
        if( InpVolPercent > 0)
        {
            vol = PointsToLots(m_symbolCurrency, InpVolPercent, slPoints);
        }
        datetime expiredDate = TimeCurrent();
        TimeAdd(expiredDate, 12, 0, 0);
        if(m_trader.BuyLimit(vol, entry, m_symbolCurrency, sl, tp, ORDER_TIME_SPECIFIED, expiredDate, comment))
        {
            //if(InpUseHedge && m_hedge != NULL)
            //    m_hedge.Disable(false);
            if(InpUseDoubleInDay && m_doubleInDay != NULL)
                m_doubleInDay.Disable(false);
        }
    }
    
//    if(canMakeOrder)
//    {
//        // Open buy
//        double entry = m_infoCurrency.ask();
//        double sl = m_lastBuff[1] - PointsToPriceShift(m_symbolCurrency, InpSLBuffPoints);
//
//        int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(sl - entry));
//        //if (slPoints > InpMaxSLPointCalc)
//        //    return;
//            
//        if (slPoints > InpMaxSLPoint)
//        {
//            slPoints = InpMaxSLPoint;
//            sl = entry - PointsToPriceShift(m_symbolCurrency, slPoints);
//        }
//        if(slPoints < InpMinSL)
//        {
//            slPoints = InpMinSL;
//            sl = entry - PointsToPriceShift(m_symbolCurrency, slPoints);
//        }
//        int tpPoints = slPoints * InpRR;
//        double tp = entry + PointsToPriceShift(m_symbolCurrency, tpPoints);
//        string comment = InpCommentPlus;
//        comment += ";01;" + slPoints + ";" + tpPoints;
//        double vol = InpVol;
//        if( InpVolPercent > 0)
//        {
//            vol = PointsToLots(m_symbolCurrency, InpVolPercent, slPoints);
//        }
//        if(m_trader.Buy(vol, m_symbolCurrency, 0, sl, tp, comment))
//        {
//            //if(InpUseHedge && m_hedge != NULL)
//            //    m_hedge.Disable(false);
//            if(InpUseDoubleInDay && m_doubleInDay != NULL)
//                m_doubleInDay.Disable(false);
//        }
//    }
}

//+------------------------------------------------------------------+
// Xử lý chung của chiến thuật mỗi khi sự kiện tick xuất hiện
//+------------------------------------------------------------------+
bool ProcessCommon()
{   
    m_infoCurrency.refresh();
    
    // Tính toán số lượng nến phát sinh
    int bars = Bars(m_symbolCurrency, m_tf);
    m_limit = bars - m_prevCalculated;
    m_prevCalculated = bars;
    return m_limit != 0;
}
void ReadIndicatorData(bool newCandle)
{
    int bars = Bars(m_symbolCurrency, m_tf);
    if(InpAutoTrade && newCandle)
    {
        if(m_fanHandler > 0)
        {
            CopyBuffer(m_fanHandler, 19, 0, bars, m_lastBuff);
            CopyBuffer(m_fanHandler, 20, 0, bars, m_upBuff);
            CopyBuffer(m_fanHandler, 21, 0, bars, m_downBuff);
            CopyBuffer(m_fanHandler, 5, 0, bars, m_ema6Buff);
        }
        CopyBuffer(m_osmaHandler, 0, 0, bars, m_osmaBuff);
        if(m_emaLongHandler > 0)
            CopyBuffer(m_emaLongHandler, 0, 0, bars, m_emaLongBuff);
        
        if(m_ressupHandler > 0)
        {
            CopyBuffer(m_ressupHandler, 0, 0, bars, m_resUpperBuffer);
            CopyBuffer(m_ressupHandler, 1, 0, bars, m_resLowerBuffer);
            CopyBuffer(m_ressupHandler, 2, 0, bars, m_supUpperBuffer);
            CopyBuffer(m_ressupHandler, 3, 0, bars, m_supLowerBuffer);
        }
    }
    
}

//+------------------------------------------------------------------+
//| Khởi tạo ban đầu
//+------------------------------------------------------------------+
int OnInit()
{
    // Khởi tạo chung
    return Init(Symbol(), InpTf);
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Sự kiện chính
//+------------------------------------------------------------------+
void OnTick()
{
    Process();
}

void OnUseGUI()
{
    // Call back to object
    m_guiTrade.OnUseGUI();
}
void OnUseStopLimit()
{
    m_guiTrade.OnUseStopLimit();
}
void OnSellCustom()
{
    m_infoCurrency.refresh();
    
    double entry, sl, tp, trigger;
    string comment = "";
    if(m_guiTrade.ExistEntryLine() && m_guiTrade.ExistSLLine() && m_guiTrade.ExistTPLine())
    {
        entry = m_guiTrade.Entry();
        sl = m_guiTrade.SL();
        tp = m_guiTrade.TP();
    }
    else
    {
        return;
    }
    // Get trigger price
    if(m_guiTrade.ExistTriggerLine())
        trigger = m_guiTrade.Trigger();
        
    if(sl <= entry || tp >= entry)
        return;

    int slPoint = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
    
    double lot = 0;
    if(m_guiTrade.UseRiskByMoney()) {
        lot = MoneyToLots(m_symbolCurrency, m_guiTrade.Money(), slPoint);
        lot = NormalizeDouble(lot, 2);
    }
    else {
        if(m_guiTrade.UseRiskByPercent())
            lot = PointsToLots(m_symbolCurrency, m_guiTrade.Risk(), slPoint);
        else
            lot = m_guiTrade.Risk();
    }
    //double lot = PointsToLots(m_symbolCurrency, m_guiTrade.Risk(), slPoint);
    //if(!m_guiTrade.UseRiskOnGUI())
    //    lot = m_guiTrade.Risk();
        
    if(lot <= 0)
        return;
        
    string orderType = "";
    if(!m_guiTrade.ExistTriggerLine()) {
        if(entry > m_infoCurrency.bid())
        {
            orderType = "Sell limit";
        }
        else if(entry < m_infoCurrency.bid())
        {
            orderType = "Sell stop";
        }
    }
    else
        orderType = "Sell stop limit";
    
    int result = IDCANCEL;
    if(lot >= 0.5)
    {
        result = MessageBox("** THE VOLUME IS TOO LARGE ! **\nPlease confirm ?", "ForexProEA", MB_OKCANCEL);
        if( result == IDCANCEL)
            return;
    }
    result = MessageBox("** " + orderType + " **\nPlease confirm the order?", "ForexProEA", MB_OKCANCEL);
    if( result == IDCANCEL)
        return;
    
    comment = InpCommentPlus;
    int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
    int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
    comment += ";01;" + slPoints + ";" + tpPoints;
    
    if(!m_guiTrade.ExistTriggerLine()) {
        if(entry > m_infoCurrency.bid())
        {
            if(m_trader.SellLimit(lot, entry, m_symbolCurrency, sl, tp, 0, 0, comment))
                m_guiTrade.ClearLines();
        }
        else if(entry < m_infoCurrency.bid())
        {
            if(m_trader.SellStop(lot, entry, m_symbolCurrency, sl, tp, 0, 0, comment))
                m_guiTrade.ClearLines();    
        }
    }
    else {
        if(m_trader.OrderOpen(m_symbolCurrency, ORDER_TYPE_SELL_STOP_LIMIT, lot, entry, trigger, sl, tp, 0, 0, comment))
            m_guiTrade.ClearLines();
    }
        
}

//+------------------------------------------------------------------+
// Sự kiện nút BUY trên bảng điều khiển
//+------------------------------------------------------------------+
void OnBuyCustom()
{
    m_infoCurrency.refresh();
    
    double entry, sl, tp, trigger;
    string comment = "";
    
    if(m_guiTrade.ExistEntryLine() && m_guiTrade.ExistSLLine() && m_guiTrade.ExistTPLine())
    {
        entry = m_guiTrade.Entry();
        sl = m_guiTrade.SL();
        tp = m_guiTrade.TP();
    }
    else
    {
        return;
    }
    // Get trigger price
    if(m_guiTrade.ExistTriggerLine())
        trigger = m_guiTrade.Trigger();
        
    if(sl >= entry || tp <= entry)
        return;

    int slPoint = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
    double lot = 0;
    if(m_guiTrade.UseRiskByMoney()) {
        lot = MoneyToLots(m_symbolCurrency, m_guiTrade.Money(), slPoint);
        lot = NormalizeDouble(lot, 2);
    }
    else {
        if(m_guiTrade.UseRiskByPercent())
            lot = PointsToLots(m_symbolCurrency, m_guiTrade.Risk(), slPoint);
        else
            lot = m_guiTrade.Risk();
    }
    //double lot = PointsToLots(m_symbolCurrency, m_guiTrade.Risk(), slPoint);
    //double lot = PointsToLots(m_symbolCurrency, m_guiTrade.Risk(), slPoint);
    //if(!m_guiTrade.UseRiskOnGUI())
    //    lot = m_guiTrade.Risk();
        
    if(lot <= 0)
        return;
    
    string orderType = "";
    if(!m_guiTrade.ExistTriggerLine()) {
        if(entry < m_infoCurrency.ask())
        {
            orderType = "Buy limit";
        }
        else if(entry > m_infoCurrency.ask())
        {
            orderType = "Buy stop";
        }
    }
    else {
        orderType = "Buy stop limit";
    }
    
    int result = IDCANCEL;
    if(lot >= 0.5)
    {
        result = MessageBox("** THE VOLUME IS TOO LARGE ! **\nPlease confirm ?", "ForexProEA", MB_OKCANCEL);
        if( result == IDCANCEL)
            return;
    }
    result = MessageBox("** " + orderType + " **\nPlease confirm the order?", "ForexProEA", MB_OKCANCEL);
    if( result == IDCANCEL)
        return;
    
    comment = InpCommentPlus;
    int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
    int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
    comment += ";01;" + slPoints + ";" + tpPoints;
    
    if(!m_guiTrade.ExistTriggerLine()) {
        if(entry < m_infoCurrency.ask())
        {
            if(m_trader.BuyLimit(lot, entry, m_symbolCurrency, sl, tp, 0, 0, comment))
                m_guiTrade.ClearLines();
        }
        else if(entry > m_infoCurrency.ask())
        {
            if(m_trader.BuyStop(lot, entry, m_symbolCurrency, sl, tp, 0, 0, comment))
                m_guiTrade.ClearLines();
        }
    }
    else {
        if(m_trader.OrderOpen(m_symbolCurrency, ORDER_TYPE_BUY_STOP_LIMIT, lot, entry, trigger, sl, tp, 0, 0, comment))
            m_guiTrade.ClearLines();
    }
}

//+------------------------------------------------------------------+
//| Sự kiện trên biểu đồ
//+------------------------------------------------------------------+
void OnChartEvent(const int id,       // event id
                const long&   lparam, // chart period
                const double& dparam, // price
                const string& sparam  // symbol
               )
{
    if(InpUseTradeToolbox)
    {
        // Xử lý sự kiện cho các controls
        m_guiTrade.ProcessChartEvent(id,lparam,dparam,sparam);
    }
}

void OnDeinit(const int reason)
{   
    if(m_guiTrade != NULL)
        m_guiTrade.ReleaseObject(reason);
    m_guiTrade = NULL;
    Print("BYE BYE BYE");
}