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

#include <stdio.h>
#include <stdlib.h>
#include <sys/io.h>
#include <linux/fcntl.h>
#include <string.h>
#include <pthread.h>
#include <nodecollection.h>
#include <baselinecollection.h>

#define THREADS_MASK ((1<<vlbi_max_threads(0))-1)
unsigned long int MAX_THREADS = 48;

static NodeCollection *vlbi_nodes = new NodeCollection();

typedef struct _vlbi_thread_t {
    void *(*__start_routine) (void *);
    void* arg;
    unsigned long m;
    int* thread_cnt;
    pthread_t th;
}vlbi_thread_t;

char* vlbi_get_version() { return (char*)VLBI_VERSION_STRING; }

static void vlbi_wait_threads(int *thread_cnt)
{
    while(((int)*thread_cnt) > 0) {
        usleep(100000);
        int nt = 0;
        for (unsigned long int t = 0; t < vlbi_max_threads(0); t++)
                nt += (((int)*thread_cnt)&(1 << t))>>t;
    }
}

static void* vlbi_thread_func(void* arg)
{
    vlbi_thread_t *t = (vlbi_thread_t*)arg;
    t->__start_routine(t->arg);
    *t->thread_cnt = (((int)(*t->thread_cnt))&t->m);
    free(t);
    return NULL;
}

static void vlbi_start_thread(void *(*__start_routine) (void *), void *arg, int *thread_cnt, int n)
{
    unsigned long nt = (1<<(n%vlbi_max_threads(0)));
    vlbi_thread_t *t = (vlbi_thread_t *)malloc(sizeof(vlbi_thread_t));
    t->__start_routine = __start_routine;
    t->arg = arg;
    t->m = (nt^THREADS_MASK);
    t->thread_cnt = thread_cnt;

    usleep(100000);
    if(((int)(*t->thread_cnt))==THREADS_MASK)
        vlbi_wait_threads(t->thread_cnt);
    *t->thread_cnt = (((int)(*t->thread_cnt))|nt);
    pthread_create(&t->th, NULL, &vlbi_thread_func, t);
}

static void* fillplane_aperture_synthesis(void* arg)
{
    VLBIBaseline *b = (VLBIBaseline*)arg;
    dsp_stream_p s = b->getStream();
    dsp_stream_p parent = (dsp_stream_p)s->parent;
    int u = parent->sizes[0];
    int v = parent->sizes[1];
    double tao = 1.0 / parent->samplerate;
    double st = vlbi_time_timespec_to_J2000time(s->starttimeutc);
    double et = st + s->len * tao;
    double *correlation = (double*)malloc(sizeof(double)*s->len);
    for(double time = st; time < et; time += tao) {
        fprintf(stderr, "\r%.3f%%   ", (time-st)*100.0/(et-st-tao));
        double *uvcoords = b->getUVCoords(time);
        if(uvcoords == NULL)
            continue;
        double sx = uvcoords[0] + u/2;
        double sy = uvcoords[1] + v/2;
        double ex = -uvcoords[0] + u/2;
        double ey = -uvcoords[1] + v/2;
        double ratio = sqrt(pow(ex-sx,2)+pow(ey-sx,2));
        free(uvcoords);
        int idx;
        b->Correlate(correlation, time, &idx);
        int len = b->first->len-idx;
        for(int p = 0; p < len; p++) {
            double ptr = p*ratio/len;
            int x = ptr * (ex - sx) / (ey - sy) + u/2;
            int y = ptr * (ey - sy) / (ex - sx) + v/2;
            if(x>=0 && x<u && y>=0&& y<v) {
                parent->buf[x+y*u] += correlation[p];
            }
        }
    }
    free(correlation);
    return NULL;
}

static void* fillplane_coverage(void* arg)
{
    VLBIBaseline *b = (VLBIBaseline*)arg;
    dsp_stream_p s = b->getStream();
    dsp_stream_p parent = (dsp_stream_p)s->parent;
    int u = parent->sizes[0];
    int v = parent->sizes[1];
    double tao = 1.0 / parent->samplerate;
    double st = vlbi_time_timespec_to_J2000time(s->starttimeutc);
    double et = st + s->len * tao;
    for(double time = st; time < et; time += tao) {
        fprintf(stderr, "\r%.3f%%   ", (time-st)*100.0/(et-st-tao));
        double *uvcoords = b->getUVCoords(time);
        if(uvcoords == NULL)
            continue;
        int U = (int)uvcoords[0];
        int V = (int)uvcoords[1];
        free(uvcoords);
        U += u / 2;
        V += v / 2;
        if(U >= 0 && U < u && V >= 0 && V < v) {
            int idx = (int)(U + V * u);
            parent->buf[idx] = 1;
            parent->buf[parent->len - idx - 1] = 1;
        }
    }
    return NULL;
}

static void* fillplane_moving_baseline(void* arg)
{
    VLBIBaseline *b = (VLBIBaseline*)arg;
    dsp_stream_p s = b->getStream();
    dsp_stream_p parent = (dsp_stream_p)s->parent;
    int u = parent->sizes[0];
    int v = parent->sizes[1];
    double *correlation = (double*)malloc(sizeof(double)*s->len);
    for(double i = 0; i < s->len; i++) {
        fprintf(stderr, "\r%.3f%%   ", i*100.0/(s->len-1));
        double *uvcoords = b->getUVCoords(i);
        if(uvcoords == NULL)
            continue;
        double sx = uvcoords[0] + u/2;
        double sy = uvcoords[1] + v/2;
        double ex = -uvcoords[0] + u/2;
        double ey = -uvcoords[1] + v/2;
        double ratio = sqrt(pow(ex-sx,2)+pow(ey-sx,2));
        free(uvcoords);
        b->Correlate(correlation, i);
        int len = b->second->len-i;
        for(int p = 0; p < len; p++) {
            double ptr = p*ratio/len;
            int x = ptr * (ex - sx) / (ey - sy) + u/2;
            int y = ptr * (ey - sy) / (ex - sx) + v/2;
            if(x>=0&&x<u&&y>=0&&y<v) {
                parent->buf[x+y*u] = correlation[p];
            }
        }
    }
    free(correlation);
    return NULL;
}

void* vlbi_init()
{
    return new NodeCollection();
}

void vlbi_exit(void* ctx)
{
    NodeCollection *nodes = (NodeCollection*)ctx;
    nodes->~NodeCollection();
    nodes = nullptr;
}

void vlbi_add_stream(void *ctx, dsp_stream_p Stream, char* name) {
    NodeCollection *nodes = (ctx != NULL) ? (NodeCollection*)ctx : vlbi_nodes;
    dsp_stream_p stream = dsp_stream_copy(Stream);
    int na = ('Z' - 'A');
    stream->arg = calloc(150, 1);
    sprintf((char*)stream->arg, "%c%c", (nodes->Count % na) + 'A', ((nodes->Count / na) % 10) + '0');
    nodes->Add(new VLBINode(stream), name);
}

void vlbi_del_stream(void *ctx, char* name) {
    NodeCollection *nodes = (ctx != NULL) ? (NodeCollection*)ctx : vlbi_nodes;
    nodes->RemoveKey(name);
}

dsp_stream_p vlbi_get_uv_plot_aperture_synthesis(vlbi_context ctx, int m, int u, int v, double *target, double freq, double sr)
{
    NodeCollection *nodes = (ctx != NULL) ? (NodeCollection*)ctx : vlbi_nodes;
    BaselineCollection *baselines = new BaselineCollection(nodes, m, u, v);
    baselines->SetFrequency(freq);
    baselines->SetSampleRate(sr);
    baselines->SetTarget(target);
    dsp_stream_p parent = baselines->getStream();
    parent->child_count = 0;
    fprintf(stderr, "%d nodes\n%d baselines\n", nodes->Count, baselines->Count);
    fprintf(stderr, "\n");
    for(int i = 0; i < baselines->Count; i++)
    {
        VLBIBaseline *b = baselines->At(i);
        vlbi_start_thread(fillplane_aperture_synthesis, b, &parent->child_count, i);
    }
    vlbi_wait_threads(&parent->child_count);
    fprintf(stderr, "\naperture synthesis plotting completed\n");
    return parent;
}

dsp_stream_p vlbi_get_uv_plot_coverage(vlbi_context ctx, int m, int u, int v, double *target, double freq, double sr)
{
    NodeCollection *nodes = (ctx != NULL) ? (NodeCollection*)ctx : vlbi_nodes;
    BaselineCollection *baselines = new BaselineCollection(nodes, m, u, v);
    baselines->SetFrequency(freq);
    baselines->SetSampleRate(sr);
    baselines->SetTarget(target);
    dsp_stream_p parent = baselines->getStream();
    parent->child_count = 0;
    fprintf(stderr, "%d nodes\n%d baselines\n", nodes->Count, baselines->Count);
    fprintf(stderr, "\n");
    for(int i = 0; i < baselines->Count; i++)
    {
        VLBIBaseline *b = baselines->At(i);
        vlbi_start_thread(fillplane_coverage, b, &parent->child_count, i);
    }
    vlbi_wait_threads(&parent->child_count);
    fprintf(stderr, "\ncoverage plotting completed\n");
    return parent;
}

dsp_stream_p vlbi_get_uv_plot_moving_baseline(void *ctx, int m, int u, int v, double *target, double freq, double sr)
{
    NodeCollection *nodes = (ctx != NULL) ? (NodeCollection*)ctx : vlbi_nodes;
    BaselineCollection *baselines = new BaselineCollection(nodes, m, u, v);
    baselines->SetFrequency(freq);
    baselines->SetSampleRate(sr);
    baselines->SetTarget(target);
    dsp_stream_p parent = baselines->getStream();
    parent->child_count = 0;
    fprintf(stderr, "%d nodes\n%d baselines\n", nodes->Count, baselines->Count);
    for(int i = 0; i < baselines->Count; i++)
    {
        VLBIBaseline *b = baselines->At(i);
        vlbi_start_thread(fillplane_moving_baseline, b, &parent->child_count, i);
    }
    vlbi_wait_threads(&parent->child_count);
    fprintf(stderr, "\nmoving baseline plotting completed\n");
    return parent;
}

dsp_stream_p vlbi_get_fft_estimate(dsp_stream_p uv)
{
    dsp_stream_p fft = dsp_stream_copy(uv);
    dsp_buffer_stretch(fft->buf, fft->len, 0.0, 1.0);
    dsp_fourier_dft_magnitude(fft);
    dsp_buffer_shift(fft);
    return fft;
}

dsp_stream_p vlbi_apply_model(dsp_stream_p uv, dsp_stream_p model)
{
    dsp_stream_p fft = dsp_stream_copy(uv);
    dsp_fourier_dft_magnitude(fft);
    dsp_fourier_dft_magnitude(model);
    dsp_buffer_shift(model);
    for(int i= 0; i < model->len; i++) {
        if(uv->buf[i] == 0)
            model->buf[i] = 0;
        else
            fft->buf[i] *= model->buf[i];
    }
    dsp_buffer_stretch(fft->buf, fft->len, 0.0, 1.0);
    dsp_fourier_dft_magnitude(fft);
    return fft;
}

int vlbi_b64readfile(char *file, void* buf)
{
    FILE *tmp = fopen(file, "r");
    if(tmp != NULL) {
        fseek(tmp, 0, SEEK_END);
        int ilen = ftell(tmp);
        int len = ilen*3/4;
        rewind(tmp);
        char *base64 = (char*)malloc(ilen);
        buf = realloc(buf, len);
        fread(base64, 1, ilen, tmp);
        fclose(tmp);
        from64tobits_fast((char*)buf, (char*)base64, ilen);
        return len;
    }
    return -1;
}
/*
unsigned char* vlbi_b64writebuf(void *buf, int* len)
{
    if(buf != NULL) {
        int olen = *len*4/3+4;
        unsigned char *base64 = (unsigned char*)malloc(olen);
        to64frombits((unsigned char*)buf, base64, *len);
        *len = olen;
        return base64;
    }
    return NULL;
}
*/

