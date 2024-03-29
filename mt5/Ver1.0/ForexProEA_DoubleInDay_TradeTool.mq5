#property description "Công cụ trade theo chiến thuật Double In A Day"
#property copyright "ForexProEA"
#property link "https://www.facebook.com/groups/forexproea/"
#property version   "12.8"



#include <trade/trade.mqh>
#include <expert/expertbase.mqh>
#include  "libs\ExpertWrapper.mqh"
#include  "libs\Common.mqh"
#include  "libs\Algorithm\GuiTrade.mqh"

// ===================================================================
// Tham số đầu vào của EA [start]
// ===================================================================
// Mã số định danh cho EA (để phân biệt với các EA khác)
input ulong InpMagicNumber = 10001273;  // Magic number
input string InpCommentPlus = "fx";               // Ghi chú thêm vào mỗi lệnh
input bool InpUseTradeToolbox = false;  // Sử dụng công cụ đặt lệnh

input group "Thiết lập chiến thuật ""double in a day"""
input bool   InpUseDoubleInDay = false;                 // Sử dụng chiến thuật topup
input int    InpDoubleInDayTopupOrders = 3;             // Số lệnh topup
input string InpDoubleInDayLotsRatioChain = "1.73;3.18;6";    // Tỉ lệ lot của top cách bằng dấu ";"
input string InpDoubleInDayDistanceRatioChain = "2.5;4.5;5.5"; // Tỉ lệ khoảng cách so với init
input double InpDoubleInDayTpRatioVsSLFromLastTopup = 2.1;  // Tỉ lệ TP so với SL tính từ order cuối
#include  "libs\\DoubleInDay.mqh"

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
        m_doubleInDay.Init(m_symbolCurrency, m_tf, m_trader, m_infoCurrency, InpMagicNumber);
        m_doubleInDay.LotRatioChain(InpDoubleInDayLotsRatioChain);
        m_doubleInDay.SetAppendComment(InpCommentPlus);
        m_doubleInDay.Topup(InpDoubleInDayTopupOrders);
        m_doubleInDay.DistancesRatio(InpDoubleInDayDistanceRatioChain);
        m_doubleInDay.TpRatioFromLastTopup(InpDoubleInDayTpRatioVsSLFromLastTopup);
        m_doubleInDay.InternalComment("x2");
    }
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
// Xử lý chính của chiến thuật
//+------------------------------------------------------------------+
void Process()
{
    // Xử lý các tác vụ chung
    ProcessCommon();
    
    // ===================================================================
    // Xử lý chính giao dịch [start]
    // ===================================================================
    if(InpUseDoubleInDay)
        m_doubleInDay.Process(m_limit);
    
    // ===================================================================
    // Xử lý chính giao dịch [ end ]
    // ===================================================================
}
//+------------------------------------------------------------------+
// Xử lý chung của chiến thuật mỗi khi sự kiện tick xuất hiện
//+------------------------------------------------------------------+
void ProcessCommon()
{
	m_infoCurrency.refresh();
    // Tính toán số lượng nến phát sinh
    int bars = Bars(m_symbolCurrency, m_tf);
    m_limit = bars - m_prevCalculated;
    m_prevCalculated = bars;
}

//+------------------------------------------------------------------+
//| Khởi tạo ban đầu
//+------------------------------------------------------------------+
int OnInit()
{
    // Khởi tạo chung
    return Init(Symbol(), Period());
    
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