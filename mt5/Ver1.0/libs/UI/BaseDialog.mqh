//+------------------------------------------------------------------+
//|                                                   BaseDialog.mqh |
//|                                                     Forex Pro EA |
//|                      https://www.facebook.com/groups/forexproea/ |
//+------------------------------------------------------------------+
#property copyright "Forex Pro EA"
#property link      "https://www.facebook.com/groups/forexproea/"
#property version   "1.00"

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Rect.mqh>
#include  "..\\Action.mqh"

//template<typename X>
class CBaseDialog: public CAppDialog
{
    private:
        long m_mouseX, m_mouseY;
        //long m_chartId;
        //int m_subwin;
        int m_internalButtonId;
        int m_internalLabelId;
        CButton *btn[20];
        CLabel *label[20];
        TAction actbtn[5];
    public:
        virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
        virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
        CBaseDialog();
        ~CBaseDialog(); 
        // ------------------------------------------------------------
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
            if(id == CHARTEVENT_CLICK)
            {
                m_mouseX = lparam;
                m_mouseY = (long)dparam;
                for(int i = ArraySize(actbtn) - 1; i >= 0; i--)
                {
                    if(btn[i] != NULL)
                    {
                        int x1, y1, x2, y2;
                        CRect rec = btn[i].Rect();
                        x1 = rec.left;
                        y1 = rec.top;
                        x2 = rec.right;
                        y2 = rec.bottom;
                        if(m_mouseX >= x1 && m_mouseX <= x2 
                           && m_mouseY >= y1 && m_mouseY <= y2)
                        {
                            //Print("Event");
                            actbtn[i]();
                            break;
                        }
                    }
                }
            }
            //this.ChartEvent(id,lparam,dparam,sparam);
            this.OnEvent(id,lparam,dparam,sparam);
            
            return true;
        }
        
        bool AddButton(CButton *&btnOut, string caption, TAction &act, int x1, int y1, int width = 40, int height = 30,
                       color backColor = clrGreenYellow, color foreColor = clrWhite)
        {
            //CButton btn;
            btn[m_internalButtonId] = new CButton();
            
            if(!btn[m_internalButtonId].Create(m_chart_id, "btn_" + (string)m_internalButtonId, m_subwin, 
                                              x1, y1, x1 + width, y1 + height))
            {
                Print("Error: " + (string)GetLastError());
                return false;
            }
            btn[m_internalButtonId].Text(caption);
            btn[m_internalButtonId].ColorBackground(backColor);
            btn[m_internalButtonId].Color(foreColor);
            
            if(!Add(btn[m_internalButtonId]))
            {
                Print("Error in adding button");
                return(false);
            }
            btnOut = btn[m_internalButtonId];
            actbtn[m_internalButtonId] = act;
            m_internalButtonId++;
            
            return true;
        }
        bool AddLabel(CLabel *&lbl, string caption, int x1, int y1, int width = 40, int height = 30)
        {
            label[m_internalLabelId] = new CLabel();
            lbl = label[m_internalLabelId];
            if(!label[m_internalLabelId].Create(m_chart_id, "label_" + (string)m_internalLabelId, m_subwin,
                                          x1, y1, x1 + width, y1 + height))
                return false;
            label[m_internalLabelId].Text(caption);
            if(!Add(label[m_internalLabelId]))
            {
                Print("Error in adding label");
                return(false);
            }
            
            m_internalLabelId++;
            return true;
            
        }
};
//+------------------------------------------------------------------+
//| Event Handling                                                   |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CBaseDialog)
//ON_EVENT(ON_CLICK, btn[0], OnClick_btn0)
EVENT_MAP_END(CAppDialog)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CBaseDialog::CBaseDialog()
{
    m_internalButtonId = 0;
    m_internalLabelId = 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CBaseDialog::~CBaseDialog()
{}
//+------------------------------------------------------------------+
bool CBaseDialog::Create(const long chart, const string name, const int subwin,
                         const int x1, const int y1, const int x2, const int y2)
{
    
    if(!CAppDialog::Create(chart, name, subwin, x1, y1, x2, y2))
        return(false);
    
//--- succeed
    return(true);
}
void OnClick_btn0()
{

}