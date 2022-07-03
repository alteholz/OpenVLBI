/*  OpenVLBI - Open Source Very Long Baseline Interferometry
*   Copyright © 2017-2022  Ilia Platone
*
*   This program is free software; you can redistribute it and/or
*   modify it under the terms of the GNU Lesser General Public
*   License as published by the Free Software Foundation; either
*   version 3 of the License, or (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
*   Lesser General Public License for more details.
*
*   You should have received a copy of the GNU Lesser General Public License
*   along with this program; if not, write to the Free Software Foundation,
*   Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#include "collection.h"

VLBICollection::VLBICollection()
{
    S = sizeof(VLBIElement);
    Items = (VLBIElement*)malloc(S);
    Count = 0;
}

VLBICollection::~VLBICollection()
{
    free(Items);
    Items = 0;
}

void VLBICollection::Add(void* el, const char* name)
{
    if(ContainsKey(name))
        return;
    VLBIElement item;
    item.item = el;
    item.name = (char*)malloc(strlen(name));
    strcpy(item.name, name);
    Count++;
    Items = (VLBIElement*)realloc(Items, S * Count);
    Items[Count - 1] = item;
}

void VLBICollection::Remove(void* el)
{
    if(!Items) return;
    if(!Contains(el))
        return;
    for(int i = 0; i < Count; i++)
    {
        if(el == Items[i].item)
        {
            Items[i].item = 0;
        }
    }
    Defrag();
}

void VLBICollection::RemoveKey(const char* name)
{
    if(!Items) return;
    if(!ContainsKey(name))
        return;
    for(int i = 0; i < Count; i++)
    {
        if(!strcmp(Items[i].name, name))
        {
            Items[i].item = 0;
            break;
        }
    }
    Defrag();
}

void* VLBICollection::Get(const char* name)
{
    if(!Items) return nullptr;
    for(int i = 0; i < Count; i++)
    {
        if(!strcmp(Items[i].name, name))
        {
            return (void*)Items[i].item;
        }
    }
    return nullptr;
}

void VLBICollection::RemoveAt(int index)
{
    if(!Items) return;
    if(index >= Count)
        return;
    Items[index].item = nullptr;
    Defrag();
}

void* VLBICollection::At(int index)
{
    if(!Items) return nullptr;
    if(index < 0 || index >= Count)
    {
        return nullptr;
    }
    return (void*)Items[index].item;
}

int VLBICollection::IndexOf(void* el)
{
    if(!Items) return -1;
    int ret = -1;
    for(int i = 0; i < Count; i++)
    {
        if(el == Items[i].item)
        {
            ret = i;
        }
    }
    return ret;
}

bool VLBICollection::ContainsKey(const char* name)
{
    if(!Items) return false;
    bool ret = false;
    for(int i = 0; i < Count; i++)
    {
        if(!strcmp(name, Items[i].name))
        {
            ret = true;
            break;
        }
    }
    return ret;
}

bool VLBICollection::Contains(void* el)
{
    if(!Items) return false;
    bool ret = false;
    for(int i = 0; i < Count; i++)
    {
        if(el == Items[i].item)
        {
            ret = true;
        }
    }
    return ret;
}

void VLBICollection::Defrag()
{
    if(!Items) return;
    int count = Count;
    Count = 0;
    for(int i = 0; i < count; i++)
    {
        if(Items[i].item != 0)
        {
            Items[Count] = Items[i];
            Count ++;
        }
    }
    Items = (VLBIElement*)realloc(Items, S * Count);
}

