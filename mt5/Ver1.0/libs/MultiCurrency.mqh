#include  "..\libs\ExpertWrapper.mqh"

input string InpSuffix = "m";
input bool INP_AUDCAD = false; //AUDCAD
input bool INP_AUDCHF = false; //AUDCHF
input bool INP_AUDJPY = false; //AUDJPY
input bool INP_AUDNZD = false; //AUDNZD
input bool INP_AUDUSD = false; //AUDUSD*
input bool INP_CADCHF = false; //CADCHF
input bool INP_CADJPY = false; //CADJPY
input bool INP_CHFJPY = false; //CHFJPY
input bool INP_EURAUD = false; //EURAUD
input bool INP_EURCAD = false; //EURCAD
input bool INP_EURCHF = false; //EURCHF
input bool INP_EURGBP = false; //EURGBP
input bool INP_EURJPY = false; //EURJPY
input bool INP_EURNZD = false; //EURNZD
input bool INP_EURUSD = false; //EURUSD*
input bool INP_GBPAUD = false; //GBPAUD
input bool INP_GBPCAD = false; //GBPCAD
input bool INP_GBPCHF = false; //GBPCHF
input bool INP_GBPJPY = false; //GBPJPY
input bool INP_GBPNZD = false; //GBPNZD
input bool INP_GBPUSD = false; //GBPUSD*
input bool INP_NZDCAD = false; //NZDCAD
input bool INP_NZDCHF = false; //NZDCHF
input bool INP_NZDJPY = false; //NZDJPY
input bool INP_NZDUSD = false; //NZDUSD*
input bool INP_USDCAD = false; //USDCAD*
input bool INP_USDCHF = false; //USDCHF*
input bool INP_USDJPY = false; //USDJPY*


// ===============================================
#define AUDCAD 0
#define AUDCHF 1
#define AUDJPY 2
#define AUDNZD 3
#define AUDUSD 4
#define CADCHF 5
#define CADJPY 6
#define CHFJPY 7
#define EURAUD 8
#define EURCAD 9
#define EURCHF 10
#define EURGBP 11
#define EURJPY 12
#define EURNZD 13
#define EURUSD 14
#define GBPAUD 15
#define GBPCAD 16
#define GBPCHF 17
#define GBPJPY 18
#define GBPNZD 19
#define GBPUSD 20
#define NZDCAD 21
#define NZDCHF 22
#define NZDJPY 23
#define NZDUSD 24
#define USDCAD 25
#define USDCHF 26
#define USDJPY 27
string symbols[28] =
  {
   "AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD","CADCHF","CADJPY",
   "CHFJPY","EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD",
   "EURUSD","GBPAUD","GBPCAD","GBPCHF","GBPJPY","GBPNZD","GBPUSD",
   "NZDCAD","NZDCHF","NZDJPY","NZDUSD","USDCAD","USDCHF","USDJPY"
  };

class CMultiCurrencyBase: public CObject
{
    protected:
        string m_symbolCurrency;
        bool m_initalized;
        int m_prevCalculated;
        CTrade m_trader;
        AllSeriesInfo m_infoCurrency;
        ENUM_TIMEFRAMES m_tf;
        int m_limit;
        
        // This virtual function is inherited in child class
        virtual bool InitMain() = 0;
        // This virtual function is inherited in child class
        virtual void ProcessMain()=NULL;
        
    public:
        // Close all positions
        virtual void CloseAllPositions()=NULL;
        
        void Init(string symbol, ENUM_TIMEFRAMES tf, const ulong magicNumber)
        {
            // ========================================
            // Init common
            
            m_trader.SetExpertMagicNumber(magicNumber); // magic
            m_trader.SetMarginMode();
            m_trader.SetTypeFillingBySymbol(m_symbolCurrency);
            // ========================================
            
            m_symbolCurrency = symbol;
            m_tf = tf;
            
            m_infoCurrency.init(m_symbolCurrency, m_tf);
            
            // Call function from child class
            InitMain();
            
            m_prevCalculated = 0;
            m_initalized = true;
        }
        
        
        void Process()
        {
            // ============================================
            // Common process
            if(!m_initalized)
                return;
            
            int bars = Bars(m_symbolCurrency, m_tf);
            m_limit = bars - m_prevCalculated;
            m_prevCalculated = bars;
            
            m_infoCurrency.refresh();
            //info1.refresh();
            // ============================================
            
            ProcessMain();
        }
        
        
};
CMultiCurrencyBase *currencyObjects[28];
string currentSymbol;

bool InitMain(ulong magicNumber)
{
    //csiHandle = iCustom(NULL, 0, "Market\\CSI_V1_1", 
    //                    20, 1, true, true, true, true, true, true, true, true, false, 100);
    //csiAll.Init(PERIOD_D1);
    
    if(INP_AUDCAD) currencyObjects[AUDCAD].Init(symbols[AUDCAD] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_AUDCHF) currencyObjects[AUDCHF].Init(symbols[AUDCHF] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_AUDJPY) currencyObjects[AUDJPY].Init(symbols[AUDJPY] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_AUDNZD) currencyObjects[AUDNZD].Init(symbols[AUDNZD] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_AUDUSD) currencyObjects[AUDUSD].Init(symbols[AUDUSD] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_CADCHF) currencyObjects[CADCHF].Init(symbols[CADCHF] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_CADJPY) currencyObjects[CADJPY].Init(symbols[CADJPY] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_CHFJPY) currencyObjects[CHFJPY].Init(symbols[CHFJPY] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_EURAUD) currencyObjects[EURAUD].Init(symbols[EURAUD] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_EURCAD) currencyObjects[EURCAD].Init(symbols[EURCAD] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_EURCHF) currencyObjects[EURCHF].Init(symbols[EURCHF] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_EURGBP) currencyObjects[EURGBP].Init(symbols[EURGBP] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_EURJPY) currencyObjects[EURJPY].Init(symbols[EURJPY] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_EURNZD) currencyObjects[EURNZD].Init(symbols[EURNZD] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_EURUSD) currencyObjects[EURUSD].Init(symbols[EURUSD] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_GBPAUD) currencyObjects[GBPAUD].Init(symbols[GBPAUD] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_GBPCAD) currencyObjects[GBPCAD].Init(symbols[GBPCAD] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_GBPCHF) currencyObjects[GBPCHF].Init(symbols[GBPCHF] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_GBPJPY) currencyObjects[GBPJPY].Init(symbols[GBPJPY] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_GBPNZD) currencyObjects[GBPNZD].Init(symbols[GBPNZD] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_GBPUSD) currencyObjects[GBPUSD].Init(symbols[GBPUSD] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_NZDCAD) currencyObjects[NZDCAD].Init(symbols[NZDCAD] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_NZDCHF) currencyObjects[NZDCHF].Init(symbols[NZDCHF] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_NZDJPY) currencyObjects[NZDJPY].Init(symbols[NZDJPY] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_NZDUSD) currencyObjects[NZDUSD].Init(symbols[NZDUSD] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_USDCAD) currencyObjects[USDCAD].Init(symbols[USDCAD] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_USDCHF) currencyObjects[USDCHF].Init(symbols[USDCHF] + InpSuffix, PERIOD_CURRENT, magicNumber);
    if(INP_USDJPY) currencyObjects[USDJPY].Init(symbols[USDJPY] + InpSuffix, PERIOD_CURRENT, magicNumber);
        
    if(!INP_AUDCAD && 
        !INP_AUDCHF && 
        !INP_AUDJPY && 
        !INP_AUDNZD && 
        !INP_AUDUSD && 
        !INP_CADCHF && 
        !INP_CADJPY && 
        !INP_CHFJPY && 
        !INP_EURAUD && 
        !INP_EURCAD && 
        !INP_EURCHF && 
        !INP_EURGBP && 
        !INP_EURJPY && 
        !INP_EURNZD && 
        !INP_EURUSD && 
        !INP_GBPAUD && 
        !INP_GBPCAD && 
        !INP_GBPCHF && 
        !INP_GBPJPY && 
        !INP_GBPNZD && 
        !INP_GBPUSD && 
        !INP_NZDCAD && 
        !INP_NZDCHF && 
        !INP_NZDJPY && 
        !INP_NZDUSD && 
        !INP_USDCAD && 
        !INP_USDCHF && 
        !INP_USDJPY
        )
    {
        currentSymbol = Symbol();
        
        if(StringCompare(currentSymbol, symbols[AUDCAD] + InpSuffix) == 0) currencyObjects[AUDCAD].Init(symbols[AUDCAD] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[AUDCHF] + InpSuffix) == 0) currencyObjects[AUDCHF].Init(symbols[AUDCHF] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[AUDJPY] + InpSuffix) == 0) currencyObjects[AUDJPY].Init(symbols[AUDJPY] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[AUDNZD] + InpSuffix) == 0) currencyObjects[AUDNZD].Init(symbols[AUDNZD] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[AUDUSD] + InpSuffix) == 0) currencyObjects[AUDUSD].Init(symbols[AUDUSD] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[CADCHF] + InpSuffix) == 0) currencyObjects[CADCHF].Init(symbols[CADCHF] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[CADJPY] + InpSuffix) == 0) currencyObjects[CADJPY].Init(symbols[CADJPY] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[CHFJPY] + InpSuffix) == 0) currencyObjects[CHFJPY].Init(symbols[CHFJPY] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[EURAUD] + InpSuffix) == 0) currencyObjects[EURAUD].Init(symbols[EURAUD] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[EURCAD] + InpSuffix) == 0) currencyObjects[EURCAD].Init(symbols[EURCAD] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[EURCHF] + InpSuffix) == 0) currencyObjects[EURCHF].Init(symbols[EURCHF] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[EURGBP] + InpSuffix) == 0) currencyObjects[EURGBP].Init(symbols[EURGBP] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[EURJPY] + InpSuffix) == 0) currencyObjects[EURJPY].Init(symbols[EURJPY] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[EURNZD] + InpSuffix) == 0) currencyObjects[EURNZD].Init(symbols[EURNZD] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[EURUSD] + InpSuffix) == 0) currencyObjects[EURUSD].Init(symbols[EURUSD] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[GBPAUD] + InpSuffix) == 0) currencyObjects[GBPAUD].Init(symbols[GBPAUD] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[GBPCAD] + InpSuffix) == 0) currencyObjects[GBPCAD].Init(symbols[GBPCAD] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[GBPCHF] + InpSuffix) == 0) currencyObjects[GBPCHF].Init(symbols[GBPCHF] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[GBPJPY] + InpSuffix) == 0) currencyObjects[GBPJPY].Init(symbols[GBPJPY] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[GBPNZD] + InpSuffix) == 0) currencyObjects[GBPNZD].Init(symbols[GBPNZD] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[GBPUSD] + InpSuffix) == 0) currencyObjects[GBPUSD].Init(symbols[GBPUSD] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[NZDCAD] + InpSuffix) == 0) currencyObjects[NZDCAD].Init(symbols[NZDCAD] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[NZDCHF] + InpSuffix) == 0) currencyObjects[NZDCHF].Init(symbols[NZDCHF] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[NZDJPY] + InpSuffix) == 0) currencyObjects[NZDJPY].Init(symbols[NZDJPY] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[NZDUSD] + InpSuffix) == 0) currencyObjects[NZDUSD].Init(symbols[NZDUSD] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[USDCAD] + InpSuffix) == 0) currencyObjects[USDCAD].Init(symbols[USDCAD] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[USDCHF] + InpSuffix) == 0) currencyObjects[USDCHF].Init(symbols[USDCHF] + InpSuffix, PERIOD_CURRENT, magicNumber);
        if(StringCompare(currentSymbol, symbols[USDJPY] + InpSuffix) == 0) currencyObjects[USDJPY].Init(symbols[USDJPY] + InpSuffix, PERIOD_CURRENT, magicNumber);
        
    }   
    return true;
}


bool ValidationSettingMultiCurrency()
{
    // ======================================
    bool validationOK = true;
    
    return validationOK;
}

void ProcessMultiCurrency(int limit)
{
    //csiAll.Process();
    //if(limit > 0)
    {
        //if(INP_AUDCAD) currencyObjects[AUDCAD].Process();
        //if(INP_AUDCHF) currencyObjects[AUDCHF].Process();
        //if(INP_AUDJPY) currencyObjects[AUDJPY].Process();
        //if(INP_AUDNZD) currencyObjects[AUDNZD].Process();
        //if(INP_AUDUSD) currencyObjects[AUDUSD].Process();
        //if(INP_CADCHF) currencyObjects[CADCHF].Process();
        //if(INP_CADJPY) currencyObjects[CADJPY].Process();
        //if(INP_CHFJPY) currencyObjects[CHFJPY].Process();
        //if(INP_EURAUD) currencyObjects[EURAUD].Process();
        //if(INP_EURCAD) currencyObjects[EURCAD].Process();
        //if(INP_EURCHF) currencyObjects[EURCHF].Process();
        //if(INP_EURGBP) currencyObjects[EURGBP].Process();
        //if(INP_EURJPY) currencyObjects[EURJPY].Process();
        //if(INP_EURNZD) currencyObjects[EURNZD].Process();
        //if(INP_EURUSD) currencyObjects[EURUSD].Process();
        //if(INP_GBPAUD) currencyObjects[GBPAUD].Process();
        //if(INP_GBPCAD) currencyObjects[GBPCAD].Process();
        //if(INP_GBPCHF) currencyObjects[GBPCHF].Process();
        //if(INP_GBPJPY) currencyObjects[GBPJPY].Process();
        //if(INP_GBPNZD) currencyObjects[GBPNZD].Process();
        //if(INP_GBPUSD) currencyObjects[GBPUSD].Process();
        //if(INP_NZDCAD) currencyObjects[NZDCAD].Process();
        //if(INP_NZDCHF) currencyObjects[NZDCHF].Process();
        //if(INP_NZDJPY) currencyObjects[NZDJPY].Process();
        //if(INP_NZDUSD) currencyObjects[NZDUSD].Process();
        //if(INP_USDCAD) currencyObjects[USDCAD].Process();
        //if(INP_USDCHF) currencyObjects[USDCHF].Process();
        //if(INP_USDJPY) currencyObjects[USDJPY].Process();
        
        if(!INP_AUDCAD && 
            !INP_AUDCHF && 
            !INP_AUDJPY && 
            !INP_AUDNZD && 
            !INP_AUDUSD && 
            !INP_CADCHF && 
            !INP_CADJPY && 
            !INP_CHFJPY && 
            !INP_EURAUD && 
            !INP_EURCAD && 
            !INP_EURCHF && 
            !INP_EURGBP && 
            !INP_EURJPY && 
            !INP_EURNZD && 
            !INP_EURUSD && 
            !INP_GBPAUD && 
            !INP_GBPCAD && 
            !INP_GBPCHF && 
            !INP_GBPJPY && 
            !INP_GBPNZD && 
            !INP_GBPUSD && 
            !INP_NZDCAD && 
            !INP_NZDCHF && 
            !INP_NZDJPY && 
            !INP_NZDUSD && 
            !INP_USDCAD && 
            !INP_USDCHF && 
            !INP_USDJPY
            )
        {
            if(StringCompare(currentSymbol, symbols[AUDCAD]+ InpSuffix) == 0) currencyObjects[AUDCAD].Process();
            if(StringCompare(currentSymbol, symbols[AUDCHF]+ InpSuffix) == 0) currencyObjects[AUDCHF].Process();
            if(StringCompare(currentSymbol, symbols[AUDJPY]+ InpSuffix) == 0) currencyObjects[AUDJPY].Process();
            if(StringCompare(currentSymbol, symbols[AUDNZD]+ InpSuffix) == 0) currencyObjects[AUDNZD].Process();
            if(StringCompare(currentSymbol, symbols[AUDUSD]+ InpSuffix) == 0) currencyObjects[AUDUSD].Process();
            if(StringCompare(currentSymbol, symbols[CADCHF]+ InpSuffix) == 0) currencyObjects[CADCHF].Process();
            if(StringCompare(currentSymbol, symbols[CADJPY]+ InpSuffix) == 0) currencyObjects[CADJPY].Process();
            if(StringCompare(currentSymbol, symbols[CHFJPY]+ InpSuffix) == 0) currencyObjects[CHFJPY].Process();
            if(StringCompare(currentSymbol, symbols[EURAUD]+ InpSuffix) == 0) currencyObjects[EURAUD].Process();
            if(StringCompare(currentSymbol, symbols[EURCAD]+ InpSuffix) == 0) currencyObjects[EURCAD].Process();
            if(StringCompare(currentSymbol, symbols[EURCHF]+ InpSuffix) == 0) currencyObjects[EURCHF].Process();
            if(StringCompare(currentSymbol, symbols[EURGBP]+ InpSuffix) == 0) currencyObjects[EURGBP].Process();
            if(StringCompare(currentSymbol, symbols[EURJPY]+ InpSuffix) == 0) currencyObjects[EURJPY].Process();
            if(StringCompare(currentSymbol, symbols[EURNZD]+ InpSuffix) == 0) currencyObjects[EURNZD].Process();
            if(StringCompare(currentSymbol, symbols[EURUSD]+ InpSuffix) == 0) currencyObjects[EURUSD].Process();
            if(StringCompare(currentSymbol, symbols[GBPAUD]+ InpSuffix) == 0) currencyObjects[GBPAUD].Process();
            if(StringCompare(currentSymbol, symbols[GBPCAD]+ InpSuffix) == 0) currencyObjects[GBPCAD].Process();
            if(StringCompare(currentSymbol, symbols[GBPCHF]+ InpSuffix) == 0) currencyObjects[GBPCHF].Process();
            if(StringCompare(currentSymbol, symbols[GBPJPY]+ InpSuffix) == 0) currencyObjects[GBPJPY].Process();
            if(StringCompare(currentSymbol, symbols[GBPNZD]+ InpSuffix) == 0) currencyObjects[GBPNZD].Process();
            if(StringCompare(currentSymbol, symbols[GBPUSD]+ InpSuffix) == 0) currencyObjects[GBPUSD].Process();
            if(StringCompare(currentSymbol, symbols[NZDCAD]+ InpSuffix) == 0) currencyObjects[NZDCAD].Process();
            if(StringCompare(currentSymbol, symbols[NZDCHF]+ InpSuffix) == 0) currencyObjects[NZDCHF].Process();
            if(StringCompare(currentSymbol, symbols[NZDJPY]+ InpSuffix) == 0) currencyObjects[NZDJPY].Process();
            if(StringCompare(currentSymbol, symbols[NZDUSD]+ InpSuffix) == 0) currencyObjects[NZDUSD].Process();
            if(StringCompare(currentSymbol, symbols[USDCAD]+ InpSuffix) == 0) currencyObjects[USDCAD].Process();
            if(StringCompare(currentSymbol, symbols[USDCHF]+ InpSuffix) == 0) currencyObjects[USDCHF].Process();
            if(StringCompare(currentSymbol, symbols[USDJPY]+ InpSuffix) == 0) currencyObjects[USDJPY].Process();
        }
    }
}


void ProcessIncomeCurrency(string incomeSymbol)
{
    if(StringCompare(incomeSymbol, symbols[AUDCAD]+ InpSuffix) == 0) currencyObjects[AUDCAD].Process();
    if(StringCompare(incomeSymbol, symbols[AUDCHF]+ InpSuffix) == 0) currencyObjects[AUDCHF].Process();
    if(StringCompare(incomeSymbol, symbols[AUDJPY]+ InpSuffix) == 0) currencyObjects[AUDJPY].Process();
    if(StringCompare(incomeSymbol, symbols[AUDNZD]+ InpSuffix) == 0) currencyObjects[AUDNZD].Process();
    if(StringCompare(incomeSymbol, symbols[AUDUSD]+ InpSuffix) == 0) currencyObjects[AUDUSD].Process();
    if(StringCompare(incomeSymbol, symbols[CADCHF]+ InpSuffix) == 0) currencyObjects[CADCHF].Process();
    if(StringCompare(incomeSymbol, symbols[CADJPY]+ InpSuffix) == 0) currencyObjects[CADJPY].Process();
    if(StringCompare(incomeSymbol, symbols[CHFJPY]+ InpSuffix) == 0) currencyObjects[CHFJPY].Process();
    if(StringCompare(incomeSymbol, symbols[EURAUD]+ InpSuffix) == 0) currencyObjects[EURAUD].Process();
    if(StringCompare(incomeSymbol, symbols[EURCAD]+ InpSuffix) == 0) currencyObjects[EURCAD].Process();
    if(StringCompare(incomeSymbol, symbols[EURCHF]+ InpSuffix) == 0) currencyObjects[EURCHF].Process();
    if(StringCompare(incomeSymbol, symbols[EURGBP]+ InpSuffix) == 0) currencyObjects[EURGBP].Process();
    if(StringCompare(incomeSymbol, symbols[EURJPY]+ InpSuffix) == 0) currencyObjects[EURJPY].Process();
    if(StringCompare(incomeSymbol, symbols[EURNZD]+ InpSuffix) == 0) currencyObjects[EURNZD].Process();
    if(StringCompare(incomeSymbol, symbols[EURUSD]+ InpSuffix) == 0) currencyObjects[EURUSD].Process();
    if(StringCompare(incomeSymbol, symbols[GBPAUD]+ InpSuffix) == 0) currencyObjects[GBPAUD].Process();
    if(StringCompare(incomeSymbol, symbols[GBPCAD]+ InpSuffix) == 0) currencyObjects[GBPCAD].Process();
    if(StringCompare(incomeSymbol, symbols[GBPCHF]+ InpSuffix) == 0) currencyObjects[GBPCHF].Process();
    if(StringCompare(incomeSymbol, symbols[GBPJPY]+ InpSuffix) == 0) currencyObjects[GBPJPY].Process();
    if(StringCompare(incomeSymbol, symbols[GBPNZD]+ InpSuffix) == 0) currencyObjects[GBPNZD].Process();
    if(StringCompare(incomeSymbol, symbols[GBPUSD]+ InpSuffix) == 0) currencyObjects[GBPUSD].Process();
    if(StringCompare(incomeSymbol, symbols[NZDCAD]+ InpSuffix) == 0) currencyObjects[NZDCAD].Process();
    if(StringCompare(incomeSymbol, symbols[NZDCHF]+ InpSuffix) == 0) currencyObjects[NZDCHF].Process();
    if(StringCompare(incomeSymbol, symbols[NZDJPY]+ InpSuffix) == 0) currencyObjects[NZDJPY].Process();
    if(StringCompare(incomeSymbol, symbols[NZDUSD]+ InpSuffix) == 0) currencyObjects[NZDUSD].Process();
    if(StringCompare(incomeSymbol, symbols[USDCAD]+ InpSuffix) == 0) currencyObjects[USDCAD].Process();
    if(StringCompare(incomeSymbol, symbols[USDCHF]+ InpSuffix) == 0) currencyObjects[USDCHF].Process();
    if(StringCompare(incomeSymbol, symbols[USDJPY]+ InpSuffix) == 0) currencyObjects[USDJPY].Process();
}
void ProcessCloseAllPositionsCurrency()
{
    if(INP_AUDCAD) currencyObjects[AUDCAD].CloseAllPositions();
    if(INP_AUDCHF) currencyObjects[AUDCHF].CloseAllPositions();
    if(INP_AUDJPY) currencyObjects[AUDJPY].CloseAllPositions();
    if(INP_AUDNZD) currencyObjects[AUDNZD].CloseAllPositions();
    if(INP_AUDUSD) currencyObjects[AUDUSD].CloseAllPositions();
    if(INP_CADCHF) currencyObjects[CADCHF].CloseAllPositions();
    if(INP_CADJPY) currencyObjects[CADJPY].CloseAllPositions();
    if(INP_CHFJPY) currencyObjects[CHFJPY].CloseAllPositions();
    if(INP_EURAUD) currencyObjects[EURAUD].CloseAllPositions();
    if(INP_EURCAD) currencyObjects[EURCAD].CloseAllPositions();
    if(INP_EURCHF) currencyObjects[EURCHF].CloseAllPositions();
    if(INP_EURGBP) currencyObjects[EURGBP].CloseAllPositions();
    if(INP_EURJPY) currencyObjects[EURJPY].CloseAllPositions();
    if(INP_EURNZD) currencyObjects[EURNZD].CloseAllPositions();
    if(INP_EURUSD) currencyObjects[EURUSD].CloseAllPositions();
    if(INP_GBPAUD) currencyObjects[GBPAUD].CloseAllPositions();
    if(INP_GBPCAD) currencyObjects[GBPCAD].CloseAllPositions();
    if(INP_GBPCHF) currencyObjects[GBPCHF].CloseAllPositions();
    if(INP_GBPJPY) currencyObjects[GBPJPY].CloseAllPositions();
    if(INP_GBPNZD) currencyObjects[GBPNZD].CloseAllPositions();
    if(INP_GBPUSD) currencyObjects[GBPUSD].CloseAllPositions();
    if(INP_NZDCAD) currencyObjects[NZDCAD].CloseAllPositions();
    if(INP_NZDCHF) currencyObjects[NZDCHF].CloseAllPositions();
    if(INP_NZDJPY) currencyObjects[NZDJPY].CloseAllPositions();
    if(INP_NZDUSD) currencyObjects[NZDUSD].CloseAllPositions();
    if(INP_USDCAD) currencyObjects[USDCAD].CloseAllPositions();
    if(INP_USDCHF) currencyObjects[USDCHF].CloseAllPositions();
    if(INP_USDJPY) currencyObjects[USDJPY].CloseAllPositions();
}

void OnChartEvent(const int id,         // event id:
                                     // if id-CHARTEVENT_CUSTOM=0-"initialization" event
                const long&   lparam, // chart period
                const double& dparam, // price
                const string& sparam  // symbol
               )
  {
   if(id>=CHARTEVENT_CUSTOM)      
     {  
        string incomeSymbol = sparam;
        if(!(!INP_AUDCAD && 
            !INP_AUDCHF && 
            !INP_AUDJPY && 
            !INP_AUDNZD && 
            !INP_AUDUSD && 
            !INP_CADCHF && 
            !INP_CADJPY && 
            !INP_CHFJPY && 
            !INP_EURAUD && 
            !INP_EURCAD && 
            !INP_EURCHF && 
            !INP_EURGBP && 
            !INP_EURJPY && 
            !INP_EURNZD && 
            !INP_EURUSD && 
            !INP_GBPAUD && 
            !INP_GBPCAD && 
            !INP_GBPCHF && 
            !INP_GBPJPY && 
            !INP_GBPNZD && 
            !INP_GBPUSD && 
            !INP_NZDCAD && 
            !INP_NZDCHF && 
            !INP_NZDJPY && 
            !INP_NZDUSD && 
            !INP_USDCAD && 
            !INP_USDCHF && 
            !INP_USDJPY))
            
        ProcessIncomeCurrency(incomeSymbol);
        
        //Print(TimeToString(TimeCurrent(),TIME_SECONDS)," -> id=",
        //    id-CHARTEVENT_CUSTOM,":  ",sparam," ",
        //    EnumToString((ENUM_TIMEFRAMES)lparam)," price=",dparam);
     }
  }
// ================================================