/*  OpenVLBI - Open Source Very Long Baseline Interferometry
    Copyright © 2017-2019  Ilia Platone

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#ifndef _BASELINECOLLECTION_H
#define _BASELINECOLLECTION_H

#include <collection.h>
#include <baseline.h>
#include <nodecollection.h>

class BaselineCollection : public VLBICollection
{
public:
    BaselineCollection(NodeCollection *nodes);
    ~BaselineCollection();
    void Update();
    void Add(VLBIBaseline *element);
    void Remove(VLBIBaseline *element);
    void RemoveAt(int index);
    VLBIBaseline *Get(const char* name);
    void RemoveKey(const char* element);
    void Clear();
    VLBIBaseline * At(int index);
    bool Contains(VLBIBaseline *element);
    bool ContainsKey(const char *element);
    int IndexOf(VLBIBaseline *element);
    void SetTarget(double *target);
    void SetFrequency(double frequency);
    void SetSampleRate(double samplerate);
    void SetDelegate(vlbi_func2_t delegate);
    inline dsp_stream_p getStream() { return Stream; }
    inline NodeCollection *getNodes() { return Nodes; }
    inline int getWidth() { return width; }
    inline int getHeight() { return height; }
    inline void setWidth(int w) { width = w; int h = getHeight(); getStream()->len = 1; getStream()->dims = 0; dsp_stream_add_dim(getStream(), w); dsp_stream_add_dim(getStream(), h); dsp_stream_alloc_buffer(getStream(), getStream()->len); }
    inline void setHeight(int h) { height = h; int w = getWidth(); getStream()->len = 1; getStream()->dims = 0; dsp_stream_add_dim(getStream(), w); dsp_stream_add_dim(getStream(), h); dsp_stream_alloc_buffer(getStream(), getStream()->len); }

protected:
    NodeCollection *Nodes;
    int width;
    int height;
    dsp_stream_p Stream;
};

#endif //_BASELINECOLLECTION_H
