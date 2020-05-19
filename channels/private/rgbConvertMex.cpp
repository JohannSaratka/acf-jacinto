/*******************************************************************************
 * Piotr's Computer Vision Matlab Toolbox      Version 3.22
 * Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
 * Licensed under the Simplified BSD License [see external/bsd.txt]
 *******************************************************************************/
#include "channels.h"
#include "channels_priv.h"

//#include "wrappers.hpp"
//#include <cmath>
//#include <typeinfo>
//#include "sse.hpp"

#define ENABLE_SSE 0

// Constants for rgb2luv conversion and lookup table for y-> l conversion
template<class oT>
oT* rgb2luv_setup(oT z, oT *mr, oT *mg, oT *mb, oT &minu,
		oT &minv, oT &un, oT &vn)
{
	// set constants for conversion
	const oT y0 = (oT) ((6.0 / 29) * (6.0 / 29) * (6.0 / 29));
	const oT a = (oT) ((29.0 / 3) * (29.0 / 3) * (29.0 / 3));
	un = (oT) 0.197833;
	vn = (oT) 0.468331;

	mr[0] = (oT) 0.430574 * z;
	mr[1] = (oT) 0.222015 * z;
	mr[2] = (oT) 0.020183 * z;

	mg[0] = (oT) 0.341550 * z;
	mg[1] = (oT) 0.706655 * z;
	mg[2] = (oT) 0.129553 * z;

	mb[0] = (oT) 0.178325 * z;
	mb[1] = (oT) 0.071330 * z;
	mb[2] = (oT) 0.939180 * z;

	oT maxi = (oT) 1.0 / 270;
	minu = -88 * maxi;
	minv = -134 * maxi;

	// build (padded) lookup table for y->l conversion assuming y in [0,1]
	// TODO constexpr?
	static oT lTable[1064];
	static bool lInit = false;
	if (lInit)
	{
		return lTable;
	}
	oT y, l;
	for (int i = 0; i < 1025; i++)
	{
		y = (oT) (i / 1024.0);
		l = y > y0 ? 116 * (oT) pow((double) y, 1.0 / 3.0) - 16 : y * a;
		lTable[i] = l * maxi;
	}
	for (int i = 1025; i < 1064; i++)
	{
		lTable[i] = lTable[i - 1];
	}
	lInit = true;
	return lTable;
}

// Convert from rgb to luv
template<class iT, class oT>
void rgb2luv(iT *I, oT *J, int n, oT nrm)
{
	oT minu, minv, un, vn, mr[3], mg[3], mb[3];
	oT *lTable = rgb2luv_setup(nrm, mr, mg, mb, minu, minv, un, vn);
	oT *L = J, *U = L + n, *V = U + n;
	iT *R = I, *G = R + n, *B = G + n;
	for (int i = 0; i < n; i++)
	{
		oT r, g, b, x, y, z, l;
		r = (oT) *R++;
		g = (oT) *G++;
		b = (oT) *B++;
		x = mr[0] * r + mg[0] * g + mb[0] * b;
		y = mr[1] * r + mg[1] * g + mb[1] * b;
		z = mr[2] * r + mg[2] * g + mb[2] * b;
		l = lTable[(int) (y * 1024)];
		*(L++) = l;
		z = 1 / (x + 15 * y + 3 * z + (oT) 1e-35);
		*(U++) = l * (13 * 4 * x * z - 13 * un) - minu;
		*(V++) = l * (13 * 9 * y * z - 13 * vn) - minv;
	}
}

// Convert from rgb to luv using sse
// TODO implement sse version
#if ENABLE_SSE
template<class iT>
void rgb2luv_sse(iT *I, float *J, int n, float nrm)
{
	const int k = 256;
	float R[k], G[k], B[k];
	if ((size_t(R) & 15 || size_t(G) & 15 || size_t(B) & 15 || size_t(I) & 15
			|| size_t(J) & 15) || n % 4 > 0)
	{
		rgb2luv(I, J, n, nrm);
		return;
	}
	int i = 0, i1, n1;
	float minu, minv, un, vn, mr[3], mg[3], mb[3];
	float *lTable = rgb2luv_setup(nrm, mr, mg, mb, minu, minv, un, vn);
	while (i < n)
	{
		n1 = i + k;
		if (n1 > n)
			n1 = n;
		float *J1 = J + i;
		float *R1, *G1, *B1;
		// convert to floats (and load input into cache)
		if (typeid(iT) != typeid(float))
		{
			R1 = R;
			G1 = G;
			B1 = B;
			iT *Ri = I + i, *Gi = Ri + n, *Bi = Gi + n;
			for (i1 = 0; i1 < (n1 - i); i1++)
			{
				R1[i1] = (float) *Ri++;
				G1[i1] = (float) *Gi++;
				B1[i1] = (float) *Bi++;
			}
		}
		else
		{
			R1 = ((float*) I) + i;
			G1 = R1 + n;
			B1 = G1 + n;
		}
		// compute RGB -> XYZ
		for (int j = 0; j < 3; j++)
		{
			__m128 _mr, _mg, _mb, *_J = (__m128*) (J1 + j * n);
			__m128 *_R = (__m128*) R1, *_G = (__m128*) G1, *_B = (__m128*) B1;
			_mr = SET(mr[j]);
			_mg = SET(mg[j]);
			_mb = SET(mb[j]);
			for (i1 = i; i1 < n1; i1 += 4)
				*(_J++) = ADD(ADD(MUL(*(_R++), _mr), MUL(*(_G++), _mg)),
						MUL(*(_B++), _mb));
		}
		{ // compute XZY -> LUV (without doing L lookup/normalization)
			__m128 _c15, _c3, _cEps, _c52, _c117, _c1024, _cun, _cvn;
			_c15 = SET(15.0f);
			_c3 = SET(3.0f);
			_cEps = SET(1e-35f);
			_c52 = SET(52.0f);
			_c117 = SET(117.0f), _c1024 = SET(1024.0f);
			_cun = SET(13 * un);
			_cvn = SET(13 * vn);
			__m128 *_X, *_Y, *_Z, _x, _y, _z;
			_X = (__m128*) J1;
			_Y = (__m128*) (J1 + n);
			_Z = (__m128*) (J1 + 2 * n);
			for (i1 = i; i1 < n1; i1 += 4)
			{
				_x = *_X;
				_y = *_Y;
				_z = *_Z;
				_z = RCP(ADD(_x, ADD(_cEps, ADD(MUL(_c15, _y), MUL(_c3, _z)))));
				*(_X++) = MUL(_c1024, _y);
				*(_Y++) = SUB(MUL(MUL(_c52, _x), _z), _cun);
				*(_Z++) = SUB(MUL(MUL(_c117, _y), _z), _cvn);
			}
		}
		{ // perform lookup for L and finalize computation of U and V
			for (i1 = i; i1 < n1; i1++)
				J[i1] = lTable[(int) J[i1]];
			__m128 *_L, *_U, *_V, _l, _cminu, _cminv;
			_L = (__m128*) J1;
			_U = (__m128*) (J1 + n);
			_V = (__m128*) (J1 + 2 * n);
			_cminu = SET(minu);
			_cminv = SET(minv);
			for (i1 = i; i1 < n1; i1 += 4)
			{
				_l = *(_L++);
				*_U = SUB(MUL(_l, *_U), _cminu);
				_U++;
				*_V = SUB(MUL(_l, *_V), _cminv);
				_V++;
			}
		}
		i = n1;
	}
}
#endif

// Convert from rgb to hsv
template<class iT, class oT>
void rgb2hsv(iT *I, oT *J, int n, oT nrm)
{
	oT *H = J;
	oT *S = H + n;
	oT *V = S + n;

	iT *R = I;
	iT *G = R + n;
	iT *B = G + n;

	for (auto i = 0; i < n; i++)
	{
		const oT r = (oT) *(R++);
		const oT g = (oT) *(G++);
		const oT b = (oT) *(B++);
		oT h, s, v, minv, maxv;

		if (r == g && g == b)
		{
			*(H++) = 0;
			*(S++) = 0;
			*(V++) = r * nrm;
			continue;
		}
		else if (r >= g && r >= b)
		{
			maxv = r;
			minv = g < b ? g : b;
			h = (g - b) / (maxv - minv) + 6;
			if (h >= 6)
			{
				h -= 6;
			}
		}
		else if (g >= r && g >= b)
		{
			maxv = g;
			minv = r < b ? r : b;
			h = (b - r) / (maxv - minv) + 2;
		}
		else
		{
			maxv = b;
			minv = r < g ? r : g;
			h = (r - g) / (maxv - minv) + 4;
		}

		h *= (oT) (1 / 6.0);
		s = 1 - minv / maxv;
		v = maxv * nrm;

		*(H++) = h;
		*(S++) = s;
		*(V++) = v;
	}
}

// Convert from rgb to gray
template<class iT, class oT>
void rgb2gray(iT *I, oT *J, int n, oT nrm)
{
	oT *GR = J;
	iT *R = I;
	iT *G = R + n;
	iT *B = G + n;

	oT mr = (oT) .2989360213 * nrm;
	oT mg = (oT) .5870430745 * nrm;
	oT mb =	(oT) .1140209043 * nrm;

	for (auto i = 0; i < n; i++)
	{
		*(GR++) = (oT) *(R++) * mr + (oT) *(G++) * mg + (oT) *(B++) * mb;
	}
}

// Convert from rgb (double) to gray (float)
// TODO Why not use template?
template<> void rgb2gray(double *I, float *J, int n, float nrm)
{
	float *GR = J;
	double *R = I;
	double *G = R + n;
	double *B = G + n;

	double mr = .2989360213 * nrm;
	double mg = .5870430745 * nrm;
	double mb = .1140209043 * nrm;

	for (auto i = 0; i < n; i++)
	{
		*(GR++) = (float) (*(R++) * mr + *(G++) * mg + *(B++) * mb);
	}
}

// Copy and normalize only
template<class iT, class oT>
void normalize(iT *I, oT *J, int n, oT nrm)
{
	for (int i = 0; i < n; i++)
	{
		*(J++) = (oT) *(I++) * nrm;
	}
}

// Convert rgb to various colorspaces
template<class iT, class oT>
py::array_t<oT> rgbConvert(py::array_t<iT> I, int n, int d, int flag, oT nrm)
{
//	oT *J = (oT*) wrMalloc(
//			n * (flag == 0 ? (d == 1 ? 1 : d / 3) : d) * sizeof(oT));
	py::array_t<oT> J = py::array_t<oT>(n * (flag == 0 ? (d == 1 ? 1 : d / 3) : d) * sizeof(oT));

	// TODO use type safe array access not raw pointers
	auto ptrI = static_cast<iT*>(I.request().ptr);
	auto ptrJ = static_cast<oT*>(J.request().ptr);

	int n1 = d * (n < 1000 ? n / 10 : 100);
	oT thr = oT(1.001);

	if (flag > 1 && nrm == 1)
	{
		for (auto i = 0; i < n1; i++)
		{
			if (I.at(i) > thr)
			{
				throw std::runtime_error(
						"For floats all values in I must be smaller than 1.");
			}
		}
	}

#if ENABLE_SSE
	bool useSse = n % 4 == 0 && typeid(oT) == typeid(float);
	if (flag == 2 && useSse)
		for (i = 0; i < d / 3; i++)
			rgb2luv_sse(I + i * n * 3, (float*) (J + i * n * 3), n,
					(float) nrm);
	else
#endif

	if ((flag == 0 && d == 1) || flag == 1)
	{
		normalize(ptrI, ptrJ, n * d, nrm);
	}
	else if (flag == 0)
	{
		for (auto i = 0; i < d / 3; i++)
		{
			rgb2gray(ptrI + i * n * 3, ptrJ + i * n * 1, n, nrm);
		}
	}
	else if (flag == 2)
	{
		for (auto i = 0; i < d / 3; i++)
		{
			rgb2luv(ptrI + i * n * 3, ptrJ + i * n * 3, n, nrm);
		}
	}
	else if (flag == 3)
	{
		for (auto i = 0; i < d / 3; i++)
		{
			rgb2hsv(ptrI + i * n * 3, ptrJ + i * n * 3, n, nrm);
		}
	}
	else
	{
		throw std::runtime_error("Unknown flag.");
	}
	return J;
}

// J = rgbConvertMex(I,flag,single); see rgbConvert.m for usage details
py::array rgbConvertMex(py::array I, int flag, bool single)
{
//void mexFunction(int nl, mxArray *pl[], int nr, const mxArray *pr[]) {

	int dims1[3];

	auto dims = I.shape();
	auto n = dims[0] * dims[1];
	auto nDims = I.ndim();
	auto d = 1;
	for (int i = 2; i < nDims; i++)
	{
		d *= dims[i];
	}

	auto idIn = I.dtype();
	// create and set output array
	dims1[0] = dims[0];
	dims1[1] = dims[1];
	if (flag == 0)
	{
		dims1[2] = (d == 1 ? 1 : d / 3);
	}
	else
	{
		dims1[2] = d;
	}

	auto idOut = single ? py::dtype("float"): py::dtype("double");

	auto J = py::array(idOut, { dims1[0], dims1[1], dims1[2] });


	// call rgbConvert() based on type of input and output array
	if (!((d == 1 && flag == 0) || flag == 1 || (d / 3) * 3 == d))
	{
		throw std::runtime_error(
				"I must have third dimension d==1 or (d/3)*3==d.");
	}

	if (idIn.is(py::dtype::of<float>()) && !single)
	{
		J = rgbConvert<float,double>(I, n, d, flag, 1.0);
	}
	else if (idIn.is(py::dtype::of<float>()) && single)
	{
		J = rgbConvert<float, float>(I, n, d, flag, 1.0f);
	}
	else if (idIn.is(py::dtype::of<double>()) && !single)
	{
		J = rgbConvert<double, double>(I, n, d, flag, 1.0);
	}
	else if (idIn.is(py::dtype::of<double>()) && single)
	{
		J = rgbConvert<double, float>(I, n, d, flag, 1.0f);
	}
	else if (idIn.is(py::dtype::of<uint8_t>()) && !single)
	{
		J = rgbConvert<uint8_t, double>( I, n, d, flag, 1.0 / 255);
	}
	else if (idIn.is(py::dtype::of<uint8_t>()) && single)
	{
		J = rgbConvert<uint8_t, float>(I, n, d, flag, 1.0f / 255);
	}
	else
	{
		throw std::runtime_error("Unsupported image type.");
	}
	return J;
}
