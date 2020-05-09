/*******************************************************************************
 * Piotr's Computer Vision Matlab Toolbox      Version 3.00
 * Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
 * Licensed under the Simplified BSD License [see external/bsd.txt]
 *******************************************************************************/
//#include "wrappers.hpp"
#include <string>
typedef unsigned char uchar;
#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>

namespace py = pybind11;
#define DEBUG
#include "channels.h"
#include "channels_priv.h"

// pad A by [pt,pb,pl,pr] and store result in B
template<class T>
void imPad(py::array_t<T> in, py::array_t<T> out, int h, int w, int d, int pt,
		int pb, int pl, int pr, int flag, T val)
{
	auto A=in.data();
	auto B=out.mutable_data();
	int h1 = h + pt;
	int hb = h1 + pb;
	int w1 = w + pl;
	int wb = w1 + pr;
	int x, y, z, mPad;
	int ct = 0, cb = 0, cl = 0, cr = 0;
	if (pt < 0)
	{
		ct = -pt;
		pt = 0;
	}
	if (pb < 0)
	{
		h1 += pb;
		cb = -pb;
		pb = 0;
	}
	if (pl < 0)
	{
		cl = -pl;
		pl = 0;
	}
	if (pr < 0)
	{
		w1 += pr;
		cr = -pr;
		pr = 0;
	}
//	int *xs, *ys;
	x = pr > pl ? pr : pl;
	y = pt > pb ? pt : pb;
	mPad = x > y ? x : y;
	bool useLookup = ((flag == 2 || flag == 3) && (mPad > h || mPad > w))
			|| (flag == 3 && (ct || cb || cl || cr));
	// helper macro for padding
#define PAD(XL,XM,XR,YT,YM,YB) \
  for(x=0;  x<pl; x++) for(y=0;  y<pt; y++) B[x*hb+y]=A[(XL+cl)*h+YT+ct]; \
  for(x=0;  x<pl; x++) for(y=pt; y<h1; y++) B[x*hb+y]=A[(XL+cl)*h+YM+ct]; \
  for(x=0;  x<pl; x++) for(y=h1; y<hb; y++) B[x*hb+y]=A[(XL+cl)*h+YB-cb]; \
  for(x=pl; x<w1; x++) for(y=0;  y<pt; y++) B[x*hb+y]=A[(XM+cl)*h+YT+ct]; \
  for(x=pl; x<w1; x++) for(y=h1; y<hb; y++) B[x*hb+y]=A[(XM+cl)*h+YB-cb]; \
  for(x=w1; x<wb; x++) for(y=0;  y<pt; y++) B[x*hb+y]=A[(XR-cr)*h+YT+ct]; \
  for(x=w1; x<wb; x++) for(y=pt; y<h1; y++) B[x*hb+y]=A[(XR-cr)*h+YM+ct]; \
  for(x=w1; x<wb; x++) for(y=h1; y<hb; y++) B[x*hb+y]=A[(XR-cr)*h+YB-cb];

//	xs = (int*) wrMalloc(wb * sizeof(int));
//	ys = (int*) wrMalloc(hb * sizeof(int));
	std::vector<int> xs;
	xs.reserve(wb);
	std::vector<int> ys;
	ys.reserve(hb);
	// build lookup table for xs and ys if necessary
	if (useLookup)
	{
		int h2 = (pt + 1) * 2 * h;
		int w2 = (pl + 1) * 2 * w;
		if (flag == 2)
		{
			for (x = 0; x < wb; x++)
			{
				z = (x - pl + w2) % (w * 2);
				xs[x] = z < w ? z : w * 2 - z - 1;
			}
			for (y = 0; y < hb; y++)
			{
				z = (y - pt + h2) % (h * 2);
				ys[y] = z < h ? z : h * 2 - z - 1;
			}
		}
		else if (flag == 3)
		{
			for (x = 0; x < wb; x++){
				xs[x] = (x - pl + w2) % w;}
			for (y = 0; y < hb; y++){
				ys[y] = (y - pt + h2) % h;}
		}
	}
	// pad by appropriate value
	for (z = 0; z < d; z++)
	{
		// copy over A to relevant region in B
		for (x = 0; x < w - cr - cl; x++){
			memcpy(B + (x + pl) * hb + pt, A + (x + cl) * h + ct,
					sizeof(T) * (h - ct - cb));}
		// set boundaries of B to appropriate values
		if (flag == 0 && val != 0)
		{ // "constant"
			for (x = 0; x < pl; x++)
			{
				for (y = 0; y < hb; y++)
				{
					B[x * hb + y] = val;
				}
			}
			for (x = pl; x < w1; x++)
			{
				for (y = 0; y < pt; y++)
				{
					B[x * hb + y] = val;
				}
			}
			for (x = pl; x < w1; x++)
			{
				for (y = h1; y < hb; y++)
				{
					B[x * hb + y] = val;
				}
			}
			for (x = w1; x < wb; x++)
			{
				for (y = 0; y < hb; y++)
				{
					B[x * hb + y] = val;
				}
			}
		}
		else if (useLookup)
		{ // "lookup"
			PAD(xs[x], xs[x], xs[x], ys[y], ys[y], ys[y]);
		}
		else if (flag == 1)
		{  // "replicate"
			PAD(0, x - pl, w - 1, 0, y-pt, h-1);
		}
		else if (flag == 2)
		{ // "symmetric"
			PAD(pl - x - 1, x - pl, w + w1 - 1 - x, pt-y-1, y-pt, h+h1-1-y);
		}
		else if (flag == 3)
		{ // "circular"
			PAD(x - pl + w, x - pl, x - pl - w, y-pt+h, y-pt, y-pt-h);
		}
		A += h * w;
		B += hb * wb;
	}
#undef PAD
}

// B = imPadMex(A,pad,type); see imPad.m for usage details
py::array imPadMex(const py::array A, const py::list pad,
		const std::string &type)
{
	unsigned int pt, pb, pl, pr, flag;
	double val = 0;
	//char type[1024];

	// argument 1: A
	auto nDims = A.ndim();
	auto id = A.dtype();
	auto ns = A.shape();
	unsigned int nCh = (nDims == 2) ? 1 : ns[2];

	checkDimensions(nDims);
	checkType(id);

	// extract padding amounts
	auto k = pad.size();
	auto p = pad;

	if (k == 1)
	{
		pt = pb = pl = pr = p[0].cast<int>();
	}
	else if (k == 2)
	{
		pt = pb = p[0].cast<int>();
		pl = pr = p[1].cast<int>();
	}
	else if (k == 4)
	{
		pt = p[0].cast<int>();
		pb = p[1].cast<int>();
		pl = p[2].cast<int>();
		pr = p[3].cast<int>();
	}
	else
	{
		throw std::invalid_argument("Input pad must have 1, 2, or 4 values.");
	}

	// figure out padding type (flag and val)
	double converted;
	bool isValue;
	try
	{
		converted = stod(type);
		isValue = true;
	}
	catch (std::invalid_argument&)
	{
		converted = 0.0;
		isValue = false;
	}

	dbg_py_print("type {}, isValue{}, converted{:.1f}", type, isValue, converted);
	if (!isValue)
	{
		if (!type.compare("replicate"))
		{
			flag = 1;
		}
		else if (!type.compare("symmetric"))
		{
			flag = 2;
		}
		else if (!type.compare("circular"))
		{
			flag = 3;
		}
		else
		{
			throw std::invalid_argument("Invalid pad value.");
		}
	}
	else
	{
		flag = 0;
		val = converted;
	}

	if (ns[0] == 0 || ns[1] == 0)
	{
		flag = 0;
	}

	// create output array
	unsigned int h = ns[0] + pt + pb;
	unsigned int w = ns[1] + pl + pr;
	if ((h < 0) || (ns[0] <= -pt) || (ns[0] <= -pb))
	{
		h = 0;
	}
	if ((w < 0) || (ns[1] <= -pl) || (ns[1] <= -pr))
	{
		w = 0;
	}
	auto B = py::array(id,
	{ h, w, nCh });
	if (h == 0 || w == 0)
	{
		return B;
	}

	if (id.is(py::dtype::of<double>()))
	{
		imPad(py::array_t<double>(A), py::array_t<double>(B), ns[0], ns[1], nCh,
				pt, pb, pl, pr, flag, val);
	}
	else if (id.is(py::dtype::of<float>()))
	{
		imPad(py::array_t<float>(A), py::array_t<float>(B), ns[0], ns[1], nCh,
				pt, pb, pl, pr, flag, float(val));
	}
	else if (id.is(py::dtype::of<uint8_t>()))
	{
		imPad(py::array_t<uint8_t>(A), py::array_t<uint8_t>(B), ns[0], ns[1],
				nCh, pt, pb, pl, pr, flag, uint8_t(val));
	}
	else
	{
		throw std::runtime_error(
				"Unsupported type. This should not happen as it was already checked.");
	}
	return B;
}
