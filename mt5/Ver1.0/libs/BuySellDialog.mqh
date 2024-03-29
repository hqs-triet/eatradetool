//+------------------------------------------------------------------+
//|                                               ControlsDialog.mqh |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include <Controls\DatePicker.mqh>
#include <Controls\ListView.mqh>
#include <Controls\ComboBox.mqh>
#include <Controls\SpinEdit.mqh>
#include <Controls\RadioGroup.mqh>
#include <Controls\CheckBox.mqh>
#include <Controls\CheckGroup.mqh>
#include <Controls\Label.mqh>
#include  "..\libs\Action.mqh"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
//--- indents and gaps
#define INDENT_LEFT                         (15)      // indent from left (with allowance for border width)
#define INDENT_TOP                          (15)      // indent from top (with allowance for border width)
#define INDENT_RIGHT                        (15)      // indent from right (with allowance for border width)
#define INDENT_BOTTOM                       (15)      // indent from bottom (with allowance for border width)
#define CONTROLS_GAP_X                      (5)       // gap by X coordinate
#define CONTROLS_GAP_Y                      (10)       // gap by Y coordinate
//--- for buttons
#define BUTTON_WIDTH                        (120)     // size by X coordinate
#define BUTTON_HEIGHT                       (50)      // size by Y coordinate
//--- for the indication area
#define EDIT_HEIGHT                         (20)      // size by Y coordinate

#define LABEL_RISK_WIDTH                    (110)      // size by Y coordinate

#define SHIFT_X (8)
#define SHIFT_Y (0)
#define COLOR_BG_SELL StringToColor("215,92,93")
#define COLOR_BG_BUY  StringToColor("38,166,154")
//+------------------------------------------------------------------+
//| Class CControlsDialog                                            |
//| Usage: main dialog of the Controls application                   |
//+------------------------------------------------------------------+
class CControlsDialog : public CAppDialog
{
private:
    CCheckBox         m_chkUseRiskByPercent;        // The checkbox: ON -> use risk by % account, OFF -> use lot
    CEdit             m_txtRisk;                    // The textbox: lot or risk (if the m_chkUseRiskByPercent is ON )
    
    CCheckBox         m_chkUseRiskByMoney;
    CEdit             m_txtRiskByMoney;             // The textbox: SL by money
    
    CCheckBox         m_chkUseDrawingLinesOnGUI;    // The checkbox to use: drawing lines Entry/SL/TP
    TAction           m_actionUseDrawingLinesOnGUI; // The action of checkbox m_chkUseDrawingLinesOnGUI
    
    CCheckBox         m_chkUseStopLimit;            // The checkbox to use buy/sell stop limit
    TAction           m_actionUseStopLimit;         // The action of checkbox m_chkUseStopLimit
    
    CLabel            m_lblRR;
    CEdit             m_txtRR;             // The textbox: show RR (view only)
    
    CLabel            m_lblVolume;          // The label: show the volume of order
    CLabel            m_lblSLMoney;         // The label: estimation of stop loss
    CLabel            m_lblTPMoney;         // The label: estimation of profit
    
    CButton           m_buttonSell;         // The button: SELL
    CButton           m_buttonBuy;          // The button: BUY
    TAction           m_actionButtonSell;   // The action of button SELL
    TAction           m_actionButtonBuy;    // The action of button BUY

    long              m_mouseX, m_mouseY;
    double            m_rr;                 // Store the ratio of RR


public:
    CControlsDialog(void);
    ~CControlsDialog(void);
    //--- create
    virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
    //--- chart event handler
    virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
    void SetActionButtonSell(TAction act)
    {
        m_actionButtonSell = act;
    }
    void SetActionButtonBuy(TAction act)
    {
        m_actionButtonBuy = act;
    }
    void SetActionUseGUI(TAction act)
    {
        m_actionUseDrawingLinesOnGUI = act;
    }
    void SetActionUseStopLimit(TAction act)
    {
        m_actionUseStopLimit = act;
    }
    bool ProcessEvent(const int id,         // event id:
                      // if id-CHARTEVENT_CUSTOM=0-"initialization" event
                      const long&   lparam, // chart period
                      const double& dparam, // price
                      const string& sparam  // symbol)
                     )
    {
        if(id == CHARTEVENT_MOUSE_MOVE) {
            m_mouseX = lparam;
            m_mouseY = (long)dparam;
        }
        ChartEvent(id,lparam,dparam,sparam);
        return true;
    }
    void getPosition(int &x1, int &y1)
    {
        x1 = Left();
        y1 = Top();
    }
    //void setPosition(int left, int top)
    //{
    //    Left(left);
    //    Top(100);
    //}
    bool CanDraw()
    {
        return m_chkUseDrawingLinesOnGUI.Checked();
    }
    bool CanDraw(bool draw)
    {
        return m_chkUseDrawingLinesOnGUI.Checked(draw);
    }
    bool UseStopLimit()
    {
        return m_chkUseStopLimit.Checked();
    }
    bool UseStopLimit(bool v)
    {
        return m_chkUseStopLimit.Checked(v);
    }
    bool UseRiskByPercent()
    {
        return m_chkUseRiskByPercent.Checked();
    }
    bool UseRiskByMoney()
    {
        return m_chkUseRiskByMoney.Checked();
    }
    double Risk()
    {
        return StringToDouble(m_txtRisk.Text());
    }
    void Risk(double r)
    {
        m_txtRisk.Text((string)r);
    }
    double Money()
    {
        return StringToDouble(m_txtRiskByMoney.Text());
    }
    //void Money(double v)
    //{
    //    m_txtRiskByMoney.Text((string)v);
    //}
    double RR()
    {
        return m_rr;
    }
    void Volume(double vol)
    {
        if(vol > 0)
            m_lblVolume.Text("Volume: " + DoubleToString(vol, 2) + " (" + vol + ")");
        else
            m_lblVolume.Text("Volume: --");
    }

    void SLMoney(double sl)
    {
        if(sl > 0)
            m_lblSLMoney.Text("Stop loss: -" + DoubleToString(sl, 2) + "$");
        else
            m_lblSLMoney.Text("Stop loss: --");
    }
    void TPMoney(double tp)
    {
        if(tp > 0)
            m_lblTPMoney.Text("Profit: +" + DoubleToString(tp, 2) + "$");
        else
            m_lblTPMoney.Text("Profit: --");
    }
    void RR(double entry, double sl, double tp)
    {
        if((sl > entry && tp > entry) || (sl < entry && tp < entry)) {
            m_txtRR.Text("x:x");
            m_rr = 1;
            return;
        }
        double deltaSL = MathAbs(entry - sl);
        double deltaTP = MathAbs(tp - entry);

        double ratio = 0;
        if(deltaSL > 0) {
            ratio = deltaTP / deltaSL;
            string text = "1:" + DoubleToString(ratio, 1);

            m_txtRR.Text(text);
            m_rr = ratio;
        }
    }
    bool MouseInsideDialog()
    {
        long x = m_mouseX, y = m_mouseY;
        int l = Left(), r = Right(), t = Top(), b = Bottom();
        //Print("x=" + x, " y=" + y + " left="+l + " right="+r+ " top=" + t + " bottom=" + b);
        if(x >= l && x <= r
                && y >= t && y <= b)
            return true;
        return false;
    }
    void CanSell(bool v)
    {
        if(v) {
            m_buttonSell.Enable();
            m_buttonSell.ColorBackground(COLOR_BG_SELL);
        }
        else {
            m_buttonSell.Disable();
            m_buttonSell.ColorBackground(clrGray);
        }
    }
    void CanBuy(bool v)
    {
        if(v) {
            m_buttonBuy.Enable();
            m_buttonBuy.ColorBackground(COLOR_BG_BUY);
        }
        else {
            m_buttonBuy.Disable();
            m_buttonBuy.ColorBackground(clrGray);
        }
    }

protected:
    //--- create dependent controls
    bool              Create_buttonSell(void);
    bool              Create_buttonBuy(void);
    void              Onclick_buttonSell(void);
    void              Onclick_buttonBuy(void);

    bool              Create_lblRisk(void);
    bool              Create_txtRisk(void);
    bool              Create_txtRiskByMoney(void);

    bool              Create_lblRR(void);
    bool              Create_txtRR(void);
    bool              Create_lblVolume(void);
    bool              Create_lblSLMoney(void);
    bool              Create_lblTPMoney(void);

    bool              Create_chkUseDrawingLinesOnGUI(void);
    bool              Create_chkUseStopLimit(void);
    bool              Create_chkUseRiskByPercent(void);
    bool              Create_chkUseRiskByMoney(void);
    
    void              OnChange_chkUseRiskByPercent(void);   // The event of checkbox m_chkUseRiskByPercent
    void              OnChange_chkUseRiskByMoney(void);   // The event of checkbox m_chkUseRiskByMoney
    
    void              OnChange_txtRisk(void);               // The event of textbox m_txtRisk
    void              OnChange_txtRiskByMoney(void);        // The event of textbox m_txtRiskByMoney
    void              OnChange_chkUseDrawingLinesOnGUI(void);             // The event of checkbox m_chkUseDrawingLinesOnGUI
    void              OnChange_chkUseStopLimit(void);             // The event of checkbox m_chkUseStopLimit
};
//+------------------------------------------------------------------+
//| Event Handling                                                   |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CControlsDialog)
ON_EVENT(ON_CLICK,m_buttonSell, Onclick_buttonSell)
ON_EVENT(ON_CLICK,m_buttonBuy,Onclick_buttonBuy)
ON_EVENT(ON_CHANGE, m_chkUseRiskByPercent, OnChange_chkUseRiskByPercent)
ON_EVENT(ON_CHANGE, m_chkUseRiskByMoney, OnChange_chkUseRiskByMoney)

ON_EVENT(ON_CHANGE, m_txtRisk, OnChange_txtRisk)
ON_EVENT(ON_CHANGE, m_txtRiskByMoney, OnChange_txtRiskByMoney)

ON_EVENT(ON_CHANGE, m_chkUseDrawingLinesOnGUI, OnChange_chkUseDrawingLinesOnGUI)
ON_EVENT(ON_CHANGE, m_chkUseStopLimit, OnChange_chkUseStopLimit)
EVENT_MAP_END(CAppDialog)
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CControlsDialog::CControlsDialog(void)
{
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CControlsDialog::~CControlsDialog(void)
{
}
//+------------------------------------------------------------------+
//| Create                                                           |
//+------------------------------------------------------------------+
bool CControlsDialog::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
{
    if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2 + SHIFT_X,y2 + SHIFT_Y))
        return(false);
        
    if(!Create_chkUseRiskByPercent())
        return(false);
    if(!Create_txtRisk())
        return(false);
        
    if(!Create_chkUseRiskByMoney())
        return(false);
    if(!Create_txtRiskByMoney())
        return(false);
        
    if(!Create_chkUseDrawingLinesOnGUI())
        return(false);
        
    if(!Create_chkUseStopLimit())
        return(false);

    if(!Create_lblRR())
        return(false);
    if(!Create_txtRR())
        return(false);

    if(!Create_lblVolume())
        return(false);

    if(!Create_lblSLMoney())
        return(false);

    if(!Create_lblTPMoney())
        return(false);
        
    if(!Create_buttonSell())
        return(false);
    if(!Create_buttonBuy())
        return(false);
        
//--- succeed
    return(true);
}



//+------------------------------------------------------------------+
//| Create the "checkbox" element                                    |
//+------------------------------------------------------------------+
bool CControlsDialog::Create_chkUseRiskByPercent(void)
{
    int x1 = INDENT_LEFT + SHIFT_X;
    int y1 = (int)(INDENT_TOP *1.3) + SHIFT_Y;
    int x2 = x1 + LABEL_RISK_WIDTH + 100;
    int y2 = y1 + EDIT_HEIGHT;
//
//--- create
    if(!m_chkUseRiskByPercent.Create(m_chart_id,m_name+"chkUseRiskByPercent",m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_chkUseRiskByPercent.Text("Risk by % account"))
        return(false);
    //if(!m_chkUseRiskByPercent.Checked(1))
    //    return(false);
    if(!Add(m_chkUseRiskByPercent))
        return(false);
//--- succeed
    return(true);
}

//+------------------------------------------------------------------+
//| Create the display field                                         |
//+------------------------------------------------------------------+
bool CControlsDialog::Create_txtRisk(void)
{
//--- coordinates
    int x1 = INDENT_LEFT + LABEL_RISK_WIDTH*1.5 + 5 + SHIFT_X;
    int y1 = INDENT_TOP + SHIFT_Y;
    int x2 = x1 + LABEL_RISK_WIDTH - INDENT_RIGHT;
    int y2 = y1 + (int)(EDIT_HEIGHT*1.5);
//--- create
    if(!m_txtRisk.Create(m_chart_id, m_name + "EditRisk",
                          m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_txtRisk.ReadOnly(false))
        return(false);

    m_txtRisk.Text("0.01");

    if(!Add(m_txtRisk))
        return(false);
//--- succeed
    return(true);
}

bool CControlsDialog::Create_chkUseRiskByMoney(void)
{
    int x1 = INDENT_LEFT + SHIFT_X;
    int y1 = INDENT_TOP + EDIT_HEIGHT*2 + EDIT_HEIGHT*0.2 + SHIFT_Y;
    int x2 = x1 + LABEL_RISK_WIDTH + 100;
    int y2 = y1 + EDIT_HEIGHT;
//
//--- create
    if(!m_chkUseRiskByMoney.Create(m_chart_id,m_name+"chkUseRiskByMoney",m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_chkUseRiskByMoney.Text("Risk by money"))
        return(false);
    //if(!m_chkUseRiskByPercent.Checked(1))
    //    return(false);
    if(!Add(m_chkUseRiskByMoney))
        return(false);
//--- succeed
    return(true);
}
bool CControlsDialog::Create_txtRiskByMoney(void)
{
//--- coordinates
    int x1 = INDENT_LEFT + LABEL_RISK_WIDTH*1.5 + 5 + SHIFT_X;
    int y1 = INDENT_TOP + EDIT_HEIGHT*2 + SHIFT_Y;
    int x2 = x1 + LABEL_RISK_WIDTH - INDENT_RIGHT;
    int y2 = y1 + (int)(EDIT_HEIGHT*1.5);
//--- create
    if(!m_txtRiskByMoney.Create(m_chart_id, m_name + "txtRiskByMoney",
                          m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_txtRiskByMoney.ReadOnly(true))
        return(false);

    //m_txtRiskByMoney.Text("");

    if(!Add(m_txtRiskByMoney))
        return(false);
//--- succeed
    return(true);
}
//+------------------------------------------------------------------+
//| Tạo checkbox: "Công cụ vẽ"                                 |
//+------------------------------------------------------------------+
bool CControlsDialog::Create_chkUseDrawingLinesOnGUI(void)
{
    int x1 = INDENT_LEFT + SHIFT_X;
    int y1 = INDENT_TOP + EDIT_HEIGHT*4 + SHIFT_Y;
    int x2 = ClientAreaWidth() - INDENT_RIGHT;
    int y2 = y1 + EDIT_HEIGHT + 5;
//
//--- create
    if(!m_chkUseDrawingLinesOnGUI.Create(m_chart_id,m_name+"chkUseDrawingLinesOnGUI",m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_chkUseDrawingLinesOnGUI.Text("Drawing lines"))
        return(false);
    if(!Add(m_chkUseDrawingLinesOnGUI))
        return(false);

//--- succeed
    return(true);
}
bool CControlsDialog::Create_chkUseStopLimit(void)
{
    int x1 = INDENT_LEFT + SHIFT_X;
    int y1 = INDENT_TOP + EDIT_HEIGHT*6 + SHIFT_Y;
    int x2 = ClientAreaWidth() - INDENT_RIGHT;
    int y2 = y1 + EDIT_HEIGHT + 5;
//
//--- create
    if(!m_chkUseStopLimit.Create(m_chart_id,m_name+"chkUseStopLimit",m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_chkUseStopLimit.Text("Use Buy/Sell Stop Limit"))
        return(false);
    if(!Add(m_chkUseStopLimit))
        return(false);

//--- succeed
    return(true);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::Create_lblRR(void)
{
//--- coordinates
    int x1 = INDENT_LEFT + SHIFT_X;
    int y1 = INDENT_TOP + EDIT_HEIGHT*8 + EDIT_HEIGHT*0.1 + SHIFT_Y;
    int x2 = x1 + LABEL_RISK_WIDTH;
    int y2 = y1 + EDIT_HEIGHT;

    if(!m_lblRR.Create(m_chart_id, m_name + "lblRR",
                       m_subwin,x1,y1,x2,y2))
        return(false);

    if(!m_lblRR.Text("Ratio R:R"))
        return(false);



    if(!Add(m_lblRR))
        return(false);
//--- succeed
    return(true);
}
//+------------------------------------------------------------------+
//| Create the display field                                         |
//+------------------------------------------------------------------+
bool CControlsDialog::Create_txtRR(void)
{
//--- coordinates
    int x1 = INDENT_LEFT + INDENT_RIGHT*6 + SHIFT_X;
    int y1 = INDENT_TOP + EDIT_HEIGHT*8 + SHIFT_Y;
    
    int x2 = x1 + LABEL_RISK_WIDTH - INDENT_RIGHT;
    int y2 = y1 + EDIT_HEIGHT * 1.5;
//--- create
    if(!m_txtRR.Create(m_chart_id,m_name+"EditRR",
                        m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_txtRR.ReadOnly(true))
        return(false);
    if(!m_txtRR.Text("1:3"))
        return false;
    if(!m_txtRR.ColorBackground(clrLightGray))
        return(false);

    m_rr = 3;
    if(!Add(m_txtRR))
        return(false);
//--- succeed
    return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::Create_lblVolume(void)
{
//--- coordinates
    int x1 = INDENT_LEFT + SHIFT_X;
    int y1 = INDENT_TOP + EDIT_HEIGHT*10 + SHIFT_Y;
    int x2 = x1 + LABEL_RISK_WIDTH;
    int y2 = y1 + EDIT_HEIGHT;

    if(!m_lblVolume.Create(m_chart_id, m_name + "lblVolume",
                           m_subwin,x1,y1,x2,y2))
        return(false);

    m_lblVolume.Text("Volume: --");
    if(!Add(m_lblVolume))
        return(false);

//--- succeed
    return(true);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::Create_lblSLMoney(void)
{
//--- coordinates
    int x1 = INDENT_LEFT + SHIFT_X;
    int y1 = INDENT_TOP + EDIT_HEIGHT*12 + SHIFT_Y;
    int x2 = x1 + LABEL_RISK_WIDTH*1.2;
    int y2 = y1 + EDIT_HEIGHT;

    // ------------------------
    if(!m_lblSLMoney.Create(m_chart_id, m_name + "lblSL",
                            m_subwin,x1,y1,x2,y2))
        return(false);
    m_lblSLMoney.Color(clrRed);
    m_lblSLMoney.Text("Stop loss: --");
    if(!Add(m_lblSLMoney))
        return(false);

//--- succeed
    return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::Create_lblTPMoney(void)
{
//--- coordinates
    int x1 = INDENT_LEFT + LABEL_RISK_WIDTH*1.5 + SHIFT_X;
    int y1 = INDENT_TOP + EDIT_HEIGHT*12 + SHIFT_Y;
    int x2 = x1 + LABEL_RISK_WIDTH*1.2;
    int y2 = y1 + EDIT_HEIGHT;

    // ------------------------
    if(!m_lblTPMoney.Create(m_chart_id, m_name + "lblTP",
                            m_subwin,x1,y1,x2,y2))
        return(false);
    m_lblTPMoney.Color(clrBlue);
    m_lblTPMoney.Text("Profit: --");
    if(!Add(m_lblTPMoney))
        return(false);

//--- succeed
    return(true);
}





//+------------------------------------------------------------------+
//| Create the button SELL                                           |
//+------------------------------------------------------------------+
bool CControlsDialog::Create_buttonSell(void)
{
//--- coordinates
    int x1 = INDENT_LEFT + CONTROLS_GAP_X * 5 + SHIFT_X;
    int y1 = INDENT_TOP + (EDIT_HEIGHT*14+CONTROLS_GAP_Y) + SHIFT_Y;
    int x2 = x1 + BUTTON_WIDTH;
    int y2 = y1 + BUTTON_HEIGHT;
//--- create
    if(!m_buttonSell.Create(m_chart_id,m_name+"SELL",m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_buttonSell.Text("SELL"))
        return(false);
    if(!m_buttonSell.ColorBackground(COLOR_BG_SELL))
        return false;
    if(!m_buttonSell.Color(clrWhite))
        return false;
    if(!Add(m_buttonSell))
        return(false);
    //--- succeed
    return(true);
}


//+------------------------------------------------------------------+
//| Create the button BUY                                            |
//+------------------------------------------------------------------+
bool CControlsDialog::Create_buttonBuy(void)
{
//--- coordinates
    int x1=INDENT_LEFT+(BUTTON_WIDTH+CONTROLS_GAP_X * 10) + SHIFT_X;
    int y1=INDENT_TOP+(EDIT_HEIGHT*14 +CONTROLS_GAP_Y) + SHIFT_Y;
    int x2=x1+BUTTON_WIDTH;
    int y2=y1+BUTTON_HEIGHT;
//--- create
    if(!m_buttonBuy.Create(m_chart_id,m_name+"Mua",m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_buttonBuy.Text("BUY"))
        return(false);
    if(!m_buttonBuy.ColorBackground(COLOR_BG_BUY))
        return false;
    if(!m_buttonBuy.Color(clrWhite))
        return false;
    if(!Add(m_buttonBuy))
        return(false);
//--- succeed
    return(true);
}

//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::Onclick_buttonSell(void)
{
    if(m_buttonSell.IsEnabled())
        if(m_actionButtonSell != NULL)
            m_actionButtonSell();
}
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::Onclick_buttonBuy(void)
{
    if(m_buttonBuy.IsEnabled())
        if(m_actionButtonBuy != NULL)
            m_actionButtonBuy();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::OnChange_chkUseRiskByPercent(void)
{
    if(m_chkUseRiskByPercent.Checked()) {
        m_chkUseRiskByMoney.Checked(false);
        OnChange_chkUseRiskByMoney();
        
        m_txtRisk.ReadOnly(false);
        m_txtRisk.ColorBackground(clrLightGreen);
    } else {
        m_txtRisk.ReadOnly(m_chkUseRiskByMoney.Checked());    
        m_txtRisk.ColorBackground(clrWhite);
    }
}
void CControlsDialog::OnChange_chkUseRiskByMoney(void)
{
    if(m_chkUseRiskByMoney.Checked()) {
        m_chkUseRiskByPercent.Checked(false);
        OnChange_chkUseRiskByPercent();
        
        m_txtRiskByMoney.ReadOnly(false);
        m_txtRiskByMoney.ColorBackground(clrLightGreen);
    } else {
        m_txtRiskByMoney.ReadOnly(true);
        m_txtRisk.ReadOnly(false);
        m_txtRiskByMoney.ColorBackground(clrWhite);
        
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::OnChange_txtRisk(void)
{
    // Nothing
}
void CControlsDialog::OnChange_txtRiskByMoney(void)
{
    // Nothing
}
void CControlsDialog::OnChange_chkUseDrawingLinesOnGUI(void)
{
    if(m_actionUseDrawingLinesOnGUI != NULL)
        m_actionUseDrawingLinesOnGUI();
}
void CControlsDialog::OnChange_chkUseStopLimit(void)
{
    if(m_actionUseStopLimit != NULL)
        m_actionUseStopLimit();
}