#include <expert/expertbase.mqh>
#include <trade/trade.mqh>
#include <indicators/indicators.mqh>

class ExpertWrapper : public CExpertBase
{
public: 
   ExpertWrapper(){
      m_used_series = (
         USE_SERIES_OPEN|USE_SERIES_HIGH|USE_SERIES_LOW|
         USE_SERIES_CLOSE|USE_SERIES_SPREAD|USE_SERIES_TIME|
         USE_SERIES_TICK_VOLUME|USE_SERIES_REAL_VOLUME
      ); 
   }
   virtual bool Init(CSymbolInfo *symbol,ENUM_TIMEFRAMES period,double point) {
      if(period == PERIOD_CURRENT)
         period = _Period;
      bool parent = CExpertBase::Init(symbol,period,point);
      m_other_period = true;
      m_other_symbol = true;
      return parent;
   }
   ENUM_TIMEFRAMES timeframe() const { return m_period; }
};

class AllSeriesInfo : public CObject
{
protected:
   CSymbolInfo      *m_symbol;
   ExpertWrapper     m_expert;
   CIndicators       m_indicators;
public:
   AllSeriesInfo(){}
   int               init(string symbol, ENUM_TIMEFRAMES timeframe);
   void              refresh();
   //--- TimeSeries access
   double            bid()              const {return m_symbol.Bid();}
   double            ask()              const {return m_symbol.Ask();}
   double            open(int i)        const {return m_expert.Open(i);}
   double            high(int i)        const {return m_expert.High(i);}
   double            low(int i)         const {return m_expert.Low(i);}
   double            close(int i)       const {return m_expert.Close(i);}
   int               spread(int i)      const {return m_expert.Spread(i);}
   datetime          time(int i)        const {return m_expert.Time(i);}
   long              tick_volume(int i) const {return m_expert.TickVolume(i);}
   long              real_volume(int i) const {return m_expert.RealVolume(i);}
   //--- returns the CSymbolInfo object
   CSymbolInfo*      symbol_info()            {return m_symbol;}
   //--- symbol and timeframe
   string            symbol()           const {return m_symbol.Name();}
   ENUM_TIMEFRAMES   timeframe()        const {return m_expert.timeframe();}
};
int AllSeriesInfo::init(string symbol,ENUM_TIMEFRAMES timeframe)
{
   m_symbol = new CSymbolInfo();
   bool symbol_up = m_symbol.Name(symbol);
   bool init_up   = m_expert.Init(m_symbol, timeframe, m_symbol.Point());
   bool expert_up = m_expert.InitIndicators(&m_indicators);
   if(!symbol_up || !init_up || !expert_up)
      return INIT_FAILED;
   return INIT_SUCCEEDED;
}
void AllSeriesInfo::refresh(void)
{
   m_indicators.Refresh();
   m_symbol.RefreshRates();
}