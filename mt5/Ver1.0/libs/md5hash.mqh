//+------------------------------------------------------------------+
//|                                                              MD5 |
//|               Copyright © 2006-2012, FINEXWARE Technologies GmbH |
//|                                                www.FINEXWARE.com |
//|      programming & development - Alexey Sergeev, Boris Gershanov |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006-2013, FINEXWARE Technologies GmbH"
#property link      "www.FINEXWARE.com"
#property version   "1.01"
#property library


static uchar _md5_PADDING[64]=
{
	0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

#define _md5_F(x, y, z)								(((x) &(y)) | ((~x) &(z)))
#define _md5_G(x, y, z)								(((x) &(z)) | ((y) &(~z)))
#define _md5_H(x, y, z)								((x) ^(y) ^(z))
#define _md5_I(x, y, z)								((y) ^((x) |(~z)))
#define _md5_ROTATE_LEFT(x, n)				(((x)<<(n)) |((x)>>(32-(n))))

#define _md5_FF(a, b, c, d, x, s, ac) { (a)+=_md5_F((b),(c),(d))+(x)+(uint)(ac);(a)=_md5_ROTATE_LEFT((a),(s));(a)+=(b); }
#define _md5_GG(a, b, c, d, x, s, ac) { (a)+=_md5_G((b),(c),(d))+(x)+(uint)(ac);(a)=_md5_ROTATE_LEFT((a),(s));(a)+=(b); }
#define _md5_HH(a, b, c, d, x, s, ac) { (a)+=_md5_H((b),(c),(d))+(x)+(uint)(ac);(a)=_md5_ROTATE_LEFT((a),(s));(a)+=(b); }
#define _md5_II(a, b, c, d, x, s, ac) { (a)+=_md5_I((b),(c),(d))+(x)+(uint)(ac);(a)=_md5_ROTATE_LEFT((a),(s));(a)+=(b); }

#define _md5_INIT_STATE_0		0x67452301
#define _md5_INIT_STATE_1		0xefcdab89
#define _md5_INIT_STATE_2		0x98badcfe
#define _md5_INIT_STATE_3		0x10325476

#define _md5_S11 7
#define _md5_S12 12
#define _md5_S13 17
#define _md5_S14 22

#define _md5_S21 5
#define _md5_S22 9
#define _md5_S23 14
#define _md5_S24 20

#define _md5_S31 4
#define _md5_S32 11
#define _md5_S33 16
#define _md5_S34 23

#define _md5_S41 6
#define _md5_S42 10
#define _md5_S43 15
#define _md5_S44 21

//------------------------------------------------------------------	class CMD5
class CMD5Hash
{
private:
	uchar m_lpszBuffer[64];
	uint m_nCount[2];
	uint m_lMD5[4];

	void ByteToDWord(int &out[], uint &in[], uint len)
	{
		uint i=0; uint j=0;
		for(; j<len; i++, j+=4) { out[i]=(int)in[j] |(int)in[j+1]<<8 |(int)in[j+2]<<16 |(int)in[j+3]<<24; }
	}

	void DWordToByte(uchar &out[], int &in[], uint len)
	{
		uint i=0; uint j=0;
		for(; j<len; i++, j+=4) { out[j]= (uchar)(in[i] & 0xff); out[j+1]=(uchar)((in[i]>>8) & 0xff); out[j+2]=(uchar)((in[i]>>16) & 0xff); out[j+3]=(uchar)((in[i]>>24) & 0xff); }
	}

	void MD5Init()
	{
		ArrayInitialize(m_lpszBuffer, 64); m_nCount[0]=m_nCount[1]=0;
		m_lMD5[0]=_md5_INIT_STATE_0; m_lMD5[1]=_md5_INIT_STATE_1; m_lMD5[2]=_md5_INIT_STATE_2; m_lMD5[3]=_md5_INIT_STATE_3;
	}

	void MD5Update(uchar &inBuf[], uint inLen)
	{
		int i, ii; int mdi; uint in[16]; int i0=0;
		mdi=(int)((m_nCount[0]>>3) & 0x3F);

		if((m_nCount[0]+((uint)inLen<<3))<m_nCount[0]) m_nCount[1]++;
		m_nCount[0]+=((uint)inLen<<3); m_nCount[1]+=((uint)inLen>>29);
		while((inLen--)>0)
		{
			m_lpszBuffer[mdi++]=inBuf[i0++];
			if(mdi==0x40)
			{
				for(i=0, ii=0; i<16; i++, ii+=4) 
					in[i]=(((uint)m_lpszBuffer[ii+3])<<24) |(((uint)m_lpszBuffer[ii+2])<<16) |(((uint)m_lpszBuffer[ii+1])<<8) |((uint)m_lpszBuffer[ii]);
				Transform(m_lMD5, in);
				mdi=0;
			}
		}
	}

	string MD5Final()
	{
		uchar bits[8]; int nIndex; uint nPadLen; const int nMD5Size=16; uchar lpszMD5[16]; string temp; string out="";
		int i;
		DWordToByte(bits, m_nCount, 8 );
		nIndex=(int)((m_nCount[0]>>3) & 0x3f);
		nPadLen=(nIndex<56) ?(56-nIndex) :(120-nIndex);
		MD5Update(_md5_PADDING, nPadLen);
		MD5Update(bits, 8);
		DWordToByte(lpszMD5, m_lMD5, nMD5Size);
		for(i=0; i<nMD5Size; i++) 
		{
			if(lpszMD5[i]==0) temp="00"; else if(lpszMD5[i]<=15) temp=StringFormat("0%x", lpszMD5[i]); else temp=StringFormat("%x", lpszMD5[i]);
			out+=temp;
		}
		lpszMD5[0]='\0';
		return(out);
	}

	void Transform(uint &buf[], uint &in[])
	{
		uint a=buf[0], b=buf[1], c=buf[2], d=buf[3];

		_md5_FF(a, b, c, d, in[ 0], _md5_S11, 0xD76AA478); 
		_md5_FF(d, a, b, c, in[ 1], _md5_S12, 0xE8C7B756); 
		_md5_FF(c, d, a, b, in[ 2], _md5_S13, 0x242070DB); 
		_md5_FF(b, c, d, a, in[ 3], _md5_S14, 0xC1BDCEEE); 
		_md5_FF(a, b, c, d, in[ 4], _md5_S11, 0xF57C0FAF); 
		_md5_FF(d, a, b, c, in[ 5], _md5_S12, 0x4787C62A); 
		_md5_FF(c, d, a, b, in[ 6], _md5_S13, 0xA8304613); 
		_md5_FF(b, c, d, a, in[ 7], _md5_S14, 0xFD469501); 
		_md5_FF(a, b, c, d, in[ 8], _md5_S11, 0x698098D8); 
		_md5_FF(d, a, b, c, in[ 9], _md5_S12, 0x8B44F7AF); 
		_md5_FF(c, d, a, b, in[10], _md5_S13, 0xFFFF5BB1); 
		_md5_FF(b, c, d, a, in[11], _md5_S14, 0x895CD7BE); 
		_md5_FF(a, b, c, d, in[12], _md5_S11, 0x6B901122); 
		_md5_FF(d, a, b, c, in[13], _md5_S12, 0xFD987193); 
		_md5_FF(c, d, a, b, in[14], _md5_S13, 0xA679438E); 
		_md5_FF(b, c, d, a, in[15], _md5_S14, 0x49B40821); 

		_md5_GG(a, b, c, d, in[ 1], _md5_S21, 0xF61E2562); 
		_md5_GG(d, a, b, c, in[ 6], _md5_S22, 0xC040B340); 
		_md5_GG(c, d, a, b, in[11], _md5_S23, 0x265E5A51); 
		_md5_GG(b, c, d, a, in[ 0], _md5_S24, 0xE9B6C7AA); 
		_md5_GG(a, b, c, d, in[ 5], _md5_S21, 0xD62F105D); 
		_md5_GG(d, a, b, c, in[10], _md5_S22, 0x02441453); 
		_md5_GG(c, d, a, b, in[15], _md5_S23, 0xD8A1E681); 
		_md5_GG(b, c, d, a, in[ 4], _md5_S24, 0xE7D3FBC8); 
		_md5_GG(a, b, c, d, in[ 9], _md5_S21, 0x21E1CDE6); 
		_md5_GG(d, a, b, c, in[14], _md5_S22, 0xC33707D6); 
		_md5_GG(c, d, a, b, in[ 3], _md5_S23, 0xF4D50D87); 
		_md5_GG(b, c, d, a, in[ 8], _md5_S24, 0x455A14ED); 
		_md5_GG(a, b, c, d, in[13], _md5_S21, 0xA9E3E905); 
		_md5_GG(d, a, b, c, in[ 2], _md5_S22, 0xFCEFA3F8); 
		_md5_GG(c, d, a, b, in[ 7], _md5_S23, 0x676F02D9); 
		_md5_GG(b, c, d, a, in[12], _md5_S24, 0x8D2A4C8A); 

		_md5_HH(a, b, c, d, in[ 5], _md5_S31, 0xFFFA3942); 
		_md5_HH(d, a, b, c, in[ 8], _md5_S32, 0x8771F681); 
		_md5_HH(c, d, a, b, in[11], _md5_S33, 0x6D9D6122); 
		_md5_HH(b, c, d, a, in[14], _md5_S34, 0xFDE5380C); 
		_md5_HH(a, b, c, d, in[ 1], _md5_S31, 0xA4BEEA44);
		_md5_HH(d, a, b, c, in[ 4], _md5_S32, 0x4BDECFA9); 
		_md5_HH(c, d, a, b, in[ 7], _md5_S33, 0xF6BB4B60); 
		_md5_HH(b, c, d, a, in[10], _md5_S34, 0xBEBFBC70); 
		_md5_HH(a, b, c, d, in[13], _md5_S31, 0x289B7EC6); 
		_md5_HH(d, a, b, c, in[ 0], _md5_S32, 0xEAA127FA); 
		_md5_HH(c, d, a, b, in[ 3], _md5_S33, 0xD4EF3085); 
		_md5_HH(b, c, d, a, in[ 6], _md5_S34, 0x04881D05);
		_md5_HH(a, b, c, d, in[ 9], _md5_S31, 0xD9D4D039); 
		_md5_HH(d, a, b, c, in[12], _md5_S32, 0xE6DB99E5); 
		_md5_HH(c, d, a, b, in[15], _md5_S33, 0x1FA27CF8); 
		_md5_HH(b, c, d, a, in[ 2], _md5_S34, 0xC4AC5665); 

		_md5_II(a, b, c, d, in[ 0], _md5_S41, 0xF4292244); 
		_md5_II(d, a, b, c, in[ 7], _md5_S42, 0x432AFF97); 
		_md5_II(c, d, a, b, in[14], _md5_S43, 0xAB9423A7); 
		_md5_II(b, c, d, a, in[ 5], _md5_S44, 0xFC93A039); 
		_md5_II(a, b, c, d, in[12], _md5_S41, 0x655B59C3); 
		_md5_II(d, a, b, c, in[ 3], _md5_S42, 0x8F0CCC92); 
		_md5_II(c, d, a, b, in[10], _md5_S43, 0xFFEFF47D); 
		_md5_II(b, c, d, a, in[ 1], _md5_S44, 0x85845DD1); 
		_md5_II(a, b, c, d, in[ 8], _md5_S41, 0x6FA87E4F); 
		_md5_II(d, a, b, c, in[15], _md5_S42, 0xFE2CE6E0); 
		_md5_II(c, d, a, b, in[ 6], _md5_S43, 0xA3014314); 
		_md5_II(b, c, d, a, in[13], _md5_S44, 0x4E0811A1); 
		_md5_II(a, b, c, d, in[ 4], _md5_S41, 0xF7537E82); 
		_md5_II(d, a, b, c, in[11], _md5_S42, 0xBD3AF235); 
		_md5_II(c, d, a, b, in[ 2], _md5_S43, 0x2AD7D2BB); 
		_md5_II(b, c, d, a, in[ 9], _md5_S44, 0xEB86D391); 

		buf[0]+=a;
		buf[1]+=b;
		buf[2]+=c;
		buf[3]+=d;
	}


public:
	CMD5Hash(void) { }
	~CMD5Hash(void) { }
	
	string Hash(uchar &in[], uint iLen) // 32-symbol array hash
	{
		MD5Init();
		MD5Update(in, iLen);
		return(MD5Final());
	}
};
