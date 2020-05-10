/*******************************************************************************
 * Piotr's Computer Vision Matlab Toolbox      Version 3.00
 * Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
 * Licensed under the Simplified BSD License [see external/bsd.txt]
 *******************************************************************************/

#include "channels.h"
#include "channels_priv.h"

// Calculate sum of cells and store result in B
template<class T>
void cellsum(py::array_t<T> A, py::array_t<T> B, int ha, int hb, int wa, int wb,
		int d, int stepSize, int cellSize)
{
	auto ret = B.mutable_unchecked();
	dbg_py_print("ha={}, hb={}, wa={}, wb={}, d={}, stepSize={}, cellSize={}\n",
					ha, hb, wa, wb, d, stepSize, cellSize);
	// for channel in num of channels
	for (int z = 0; z < d; z++)
	{
//		T *aChan=&A[z*wa*ha];
//		T *bChan=&B[z*wb*hb];
		for (int x = 0; x < wb; x++)
		{
			for (int y = 0; y < hb; y++)
			{
				int xStart = std::min<int>(x * stepSize, wa);
				int xEnd = std::min<int>(xStart + cellSize, wa);

				int yStart = std::min<int>(y * stepSize, ha);
				int yEnd = std::min<int>(yStart + cellSize, ha);
				dbg_py_print("x={}, xStart={}, xEnd={}, y={}, yStart={}, yEnd={}",
								x, xStart, xEnd, y, yStart, yEnd);
				T bVal = 0;
				for (int col = xStart; col < xEnd; col++)
				{
					for (int row = yStart; row < yEnd; row++)
					{
						//bVal += aChan[col * ha + row];
						bVal += A.at(row, col, z);
					}
				}
				//bChan[x * hb + y] = bVal;
				ret(y, x, z) = bVal;

			}
		}
	}
}



py::array chnsCellSumMex(py::array data, unsigned int stepSize,
		unsigned int cellSize, unsigned int h, unsigned int w)
{
	dbg_py_print("type {}", data.dtype());
	// argument 1: data
	auto nDims = data.ndim();
	auto id = data.dtype();
	auto ns = data.shape();
	unsigned int nCh = (nDims == 2) ? 1 : ns[2];
//	dbg_py_print("nDims={} nCh={}",nDims, nCh);

	checkDimensions(nDims);
	checkType(id);

	// create output array
	auto B = py::array(id,{ h, w, nCh });

//	dbg_py_print("ns[0]={}, h={}, ns[1]={}, w={}, nCh={}, stepSize={}, cellSize={}\n",
//		ns[0], h, ns[1], w, nCh, stepSize, cellSize);

	// calculate cell sum (w appropriate type)
	if (id.is(py::dtype::of<double>()))
	{
		cellsum(py::array_t<double>(data), py::array_t<double>(B), ns[0], h,
				ns[1], w, nCh, stepSize, cellSize);
	}
	else if (id.is(py::dtype::of<float>()))
	{
		cellsum(py::array_t<float>(data), py::array_t<float>(B), ns[0], h,
				ns[1], w, nCh, stepSize, cellSize);
	}
	else if (id.is(py::dtype::of<uint8_t>()))
	{
		// TODO Enable type uint8 for chnsCellSum
#if 0
		int n = ns[0] * ns[1] * nCh;
		int m = h * w * nCh;
		float *A1 = (float*) mxMalloc(n * sizeof(float));
		float *B1 = (float*) mxCalloc(m, sizeof(float));

		for (int i = 0; i < n; i++)
		{
			A1[i] = (float) ((uchar*) A)[i];
		}

		cellsum(A1, B1, ns[0], h, ns[1], w, nCh, stepSize, cellSize);

		for (int i = 0; i < m; i++)
		{
			((uchar*) B)[i] = (uchar) (B1[i] + .5);
		}
		mxFree(A1);
		mxFree(B1);
#endif
	}
	else
	{
		throw std::runtime_error(
				"Unsupported type. This should not happen as it was already checked.");
	}
	return B;
}
