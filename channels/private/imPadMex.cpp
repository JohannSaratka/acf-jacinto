/*******************************************************************************
 * Piotr's Computer Vision Matlab Toolbox      Version 3.00
 * Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
 * Licensed under the Simplified BSD License [see external/bsd.txt]
 *******************************************************************************/
#include <string>
//#define DEBUG
#include "channels.h"
#include "channels_priv.h"

enum class PadMode
{
	constant, replicate, symmetric, circular
};

// pad A by [pt,pb,pl,pr] and store result in B
template<class T>
void imPad(py::array_t<T> in, py::array_t<T> out, int h, int w, int d, int pt,
		int pb, int pl, int pr, PadMode flag, T val)
{
	// TODO use type safe array access not raw pointers
	//	auto A = in.unchecked();
	//	auto B = out.mutable_unchecked();
	auto A = (T*) in.request().ptr;
	auto B = (T*) out.request().ptr;
	int h1 = h + pt;
	int hb = h1 + pb;
	int w1 = w + pl;
	int wb = w1 + pr;

	// memory layout looks like this
	// x0, x1,...,xwb-1
	// xwb+0, xwb+1,...,2*xwb-1
	// ...
	// (hb-1)*xwb+0,...,hb*xwb-1
	//	int i=0;
	//	for (int y = 0; y < hb; y++)
	//	{
	//		for (int x = 0; x < wb; x++)
	//		{
	//
	//			dbg_py_print("({},{})", x, y);
	//			D[y * wb + x] = i++;
	//			dbg_py_print("{}\n", out);
	//		}
	//	}

	int x, y, z, mPad;
	int ct = 0;
	int cb = 0;
	int cl = 0;
	int cr = 0;
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

	x = pr > pl ? pr : pl;
	y = pt > pb ? pt : pb;
	mPad = x > y ? x : y;
	bool useLookup = ((flag == PadMode::symmetric || flag == PadMode::circular)
			&& (mPad > h || mPad > w))
			|| (flag == PadMode::circular && (ct || cb || cl || cr));
	// TODO translate to function
	// helper macro for padding
#define PAD(XL,XM,XR,YT,YM,YB) \
	for(int x=0; x<pl; x++)  for(int y=0; y<pt; y++)  B[x+y*wb] = A[(XL+cl)+(YT+ct)*w]; \
	for(int x=0; x<pl; x++)  for(int y=pt; y<h1; y++) B[x+y*wb] = A[(XL+cl)+(YM+ct)*w]; \
	for(int x=0; x<pl; x++)  for(int y=h1; y<hb; y++) B[x+y*wb] = A[(XL+cl)+(YB-cb)*w]; \
	for(int x=pl; x<w1; x++) for(int y=0; y<pt; y++)  B[x+y*wb] = A[(XM+cl)+(YT+ct)*w]; \
	for(int x=pl; x<w1; x++) for(int y=h1; y<hb; y++) B[x+y*wb] = A[(XM+cl)+(YB-cb)*w]; \
	for(int x=w1; x<wb; x++) for(int y=0; y<pt; y++)  B[x+y*wb] = A[(XR-cr)+(YT+ct)*w]; \
	for(int x=w1; x<wb; x++) for(int y=pt; y<h1; y++) B[x+y*wb] = A[(XR-cr)+(YM+ct)*w]; \
	for(int x=w1; x<wb; x++) for(int y=h1; y<hb; y++) B[x+y*wb] = A[(XR-cr)+(YB-cb)*w];

	std::vector<int> xs;
	xs.reserve(wb);
	std::vector<int> ys;
	ys.reserve(hb);
	// build lookup table for xs and ys if necessary
	if (useLookup)
	{
		int h2 = (pt + 1) * 2 * h;
		int w2 = (pl + 1) * 2 * w;
		if (flag == PadMode::symmetric)
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
		else if (flag == PadMode::circular)
		{
			for (x = 0; x < wb; x++)
			{
				xs[x] = (x - pl + w2) % w;
			}
			for (y = 0; y < hb; y++)
			{
				ys[y] = (y - pt + h2) % h;
			}
		}
	}
	// pad by appropriate value
	for (z = 0; z < d; z++)
	{
		// copy over A to relevant region in B
		for (int y = 0; y < h; y++)
		{
			//memcpy(B+(x+pl)*hb+pt,A+(x+cl)*h+ct,sizeof(T)*(h-ct-cb));
			memcpy(B + (y + pt) * wb + pl, A + y * w, sizeof(T) * w);
			//dbg_py_print("{}\n", out);
		}

		// set boundaries of B to appropriate values
		if (flag == PadMode::constant && val != 0)
		{ // "constant"
			for (x = 0; x < pl; x++)
			{
				for (y = 0; y < hb; y++)
				{
					// Using indexing on array: B(y,x) = val;
					B[y * wb + x] = val;

				}
			}
			for (x = pl; x < w1; x++)
			{
				for (y = 0; y < pt; y++)
				{
					B[y * wb + x] = val;
				}
			}
			for (x = pl; x < w1; x++)
			{
				for (y = h1; y < hb; y++)
				{
					B[y * wb + x] = val;
				}
			}
			for (x = w1; x < wb; x++)
			{
				for (y = 0; y < hb; y++)
				{
					B[y * wb + x] = val;
				}
			}
		}
		else if (useLookup)
		{ // "lookup"
			PAD(xs[x], xs[x], xs[x], ys[y], ys[y], ys[y]);
		}
		else if (flag == PadMode::replicate)
		{  // "replicate"
			PAD(0, x - pl, w - 1, 0, y-pt, h-1);
		}
		else if (flag == PadMode::symmetric)
		{ // "symmetric"
			PAD(pl - x - 1, x - pl, w + w1 - 1 - x, pt-y-1, y-pt, h+h1-1-y);
		}
		else if (flag == PadMode::circular)
		{ // "circular"
			PAD(x - pl + w, x - pl, x - pl - w, y-pt+h, y-pt, y-pt-h);
		}
		// TODO 3d case
//		A += h * w;
//		B += hb * wb;
	}
#undef PAD
}

// B = imPadMex(A,pad,type); see imPad.m for usage details
py::array imPadMex(const py::array A, const py::list pad,
		const std::string &type)
{
	int pt, pb, pl, pr;
	PadMode flag;
	double val = 0;

	// argument 1: A
	auto nDims = A.ndim();
	auto id = A.dtype();
	auto ns = A.shape();
	unsigned int nCh = (nDims == 2) ? 1 : ns[2];

	checkDimensions(nDims);
	checkType(id);

	// extract padding amounts
	auto k = pad.size();

	if (k == 1)
	{
		pt = pb = pl = pr = pad[0].cast<int>();
	}
	else if (k == 2)
	{
		pt = pb = pad[0].cast<int>();
		pl = pr = pad[1].cast<int>();
	}
	else if (k == 4)
	{
		pt = pad[0].cast<int>();
		pb = pad[1].cast<int>();
		pl = pad[2].cast<int>();
		pr = pad[3].cast<int>();
	}
	else
	{
		throw std::invalid_argument("Input pad must have 1, 2, or 4 values.");
	}
	dbg_py_print("k={} pt={} pb={} pl={} pr={}", k, pt, pb, pl, pr);
	// figure out padding type (flag and val)
	double converted;
	bool isValue;
	try
	{
		converted = stod(type);
		isValue = true;
	} catch (std::invalid_argument&)
	{
		converted = 0.0;
		isValue = false;
	}

	dbg_py_print("type={}, isValue={}, converted={:.1f}", type, isValue,
			converted);
	if (!isValue)
	{
		if (!type.compare("replicate"))
		{
			flag = PadMode::replicate;
		}
		else if (!type.compare("symmetric"))
		{
			flag = PadMode::symmetric;
		}
		else if (!type.compare("circular"))
		{
			flag = PadMode::circular;
		}
		else
		{
			throw std::invalid_argument("Invalid pad value.");
		}
	}
	else
	{
		flag = PadMode::constant;
		val = converted;
	}

	if (ns[0] == 0 || ns[1] == 0)
	{
		flag = PadMode::constant;
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
	dbg_py_print("h={} w={} nCh={} ", h, w, nCh);
	py::array B;
	if (nCh == 1)
	{
		B = py::array(id,
		{ h, w });
	}
	else
	{
		B = py::array(id,
		{ h, w, nCh });
	}
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
