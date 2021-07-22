#include "vlbi_client.h"

static int is_running = 1;

VLBI::Client::Client()
{
	f = stdout;
	Ra=0;
    Dec = 0;
    Freq = 1420000000;
    SampleRate = 100000000;
    Bps = 8;
    Gain = 1;
    w = 128;
    h = 128;
	contexts = new InstanceCollection();
	model = dsp_stream_new();
	uv = dsp_stream_new();
	fft = dsp_stream_new();
}

VLBI::Client::~Client()
{
    if(context != NULL) {
        vlbi_exit(context);
    }
}

static double fillone_delegate(double x, double y) {
    return 1.0;
}

void VLBI::Client::AddNode(char *name, dsp_location *locations, void *buf, int bytelen, timespec starttime, bool geo)
{
	dsp_stream_p node = dsp_stream_new();
	int len = bytelen*8/abs(Bps);
	dsp_stream_add_dim(node, len);
	dsp_stream_alloc_buffer(node, len);
	switch(Bps) {
		case 16:
		dsp_buffer_copy(((unsigned short int*)buf), node->buf, len);
		break;
		case 32:
		dsp_buffer_copy(((unsigned int*)buf), node->buf, len);
		break;
		case 64:
		dsp_buffer_copy(((unsigned long int*)buf), node->buf, len);
		break;
		case -32:
		dsp_buffer_copy(((float*)buf), node->buf, len);
		break;
		case -64:
		dsp_buffer_copy(((double*)buf), node->buf, len);
		break;
		case 8:
		dsp_buffer_copy(((unsigned char*)buf), node->buf, len);
		break;
		default:
		break;
	}
    node->location = locations;
	memcpy(&node->starttimeutc, &starttime, sizeof(timespec));
    vlbi_add_stream(context, node, name, geo);
}

void VLBI::Client::DelNode(char *name)
{
	vlbi_del_stream(context, name);
}

dsp_stream_p VLBI::Client::GetPlot(int u, int v, int type, bool nodelay)
{
	dsp_stream_p plot;
	double coords[3] = { Ra, Dec };
    plot = vlbi_get_uv_plot(context, u, v, coords, Freq, SampleRate, nodelay, (type&APERTURE_SYNTHESIS) == 0, (type&UV_COVERAGE) != 0 ? fillone_delegate : vlbi_default_delegate);
    return plot;
}

void VLBI::Client::Parse(char* cmd, char* arg, char* value)
{
    if(!strcmp(cmd, "set")) {
        if(!strcmp(arg, "context")) {
            if(contexts->ContainsKey(value)) {
                SetContext(contexts->Get(value));
            }
        }
        else if(!strcmp(arg, "resolution")) {
            char* W = strtok(value, "x");
            char* H = strtok(NULL, "x");
            w = (int)atof(W);
            h = (int)atof(H);
        }
        else if(!strcmp(arg, "target")) {
            char* ra = strtok(value, ",");
            char* dec = strtok(NULL, ",");
            Ra = (double)atof(ra);
            Dec = (double)atof(dec);
        }
        else if(!strcmp(arg, "frequency")) {
            Freq = (double)atof(value);
        }
        else if(!strcmp(arg, "samplerate")) {
            SampleRate = (double)atof(value);
        }
        else if(!strcmp(arg, "bitspersample")) {
            Bps = (int)atof(value);
        }
        else if(!strcmp(arg, "location")) {
            double lat, lon, el;
            char *t = strtok(value, ",");
            lat = (int)atof(t);
            t = strtok(NULL, ",");
            lon = (int)atof(t);
            t = strtok(NULL, ",");
            el = (int)atof(t);
            vlbi_set_location(GetContext(), lat, lon, el);
        }
        else if(!strcmp(arg, "model")) {
        }
    }
    else if(!strcmp(cmd, "get")) {
        if(!strcmp(arg, "observation")) {
            int type = 0;
            char *t = strtok(value, "_");
            bool nodelay = false;
            if(!strcmp(t, "synthesis")) {
                type |= APERTURE_SYNTHESIS;
            } else if(!strcmp(t, "movingbase")) {
                type &= ~APERTURE_SYNTHESIS;
            } else {
                return;
            }
            t = strtok(NULL, "_");
            if(!strcmp(t, "nodelay")) {
                nodelay = true;
            } else if(!strcmp(t, "delay")) {
                nodelay = false;
            } else {
                return;
            }
            t = strtok(NULL, "_");
            if(!strcmp(t, "idft")) {
                type |= UV_IDFT;
            } else if(!strcmp(t, "raw")) {
            } else if(!strcmp(t, "coverage")) {
                type |= UV_COVERAGE;
            } else {
                return;
            }
            dsp_stream_p plot = GetPlot(w, h, type, nodelay);
            if (plot != NULL) {
                if((type & UV_IDFT) != 0)
                    vlbi_get_ifft_estimate(plot);
                dsp_buffer_stretch(plot->buf, plot->len, 0.0, 255.0);
                int ilen = plot->len;
                int olen = ilen*4/3+4;
                unsigned char* buf = (unsigned char*)malloc(plot->len);
                dsp_buffer_copy(plot->buf, buf, plot->len);
                char* base64 = (char*)malloc(olen);
                to64frombits((unsigned char*)base64, (unsigned char*)buf, ilen);
                fwrite(base64, 1, olen, f);
                free(base64);
                dsp_stream_free(plot);
            }
        }
    }
    else if(!strcmp(cmd, "add")) {
        if(!strcmp(arg, "context")) {
            if(!contexts->ContainsKey(value)) {
                contexts->Add(vlbi_init(), value);
            }
        }
        else if(!strcmp(arg, "node")) {
            char name[32], file[150], date[64];
            double lat, lon, el;
            int geo = 2;
            char* k = strtok(value, ",");
            strcpy(name, k);
            k = strtok(NULL, ",");
            if(!strcmp(k, "geo"))
                geo = 1;
            else if(!strcmp(k, "xyz"));
            else {
                geo = 0;
                return;
            }
            k = strtok(NULL, ",");
            lat = (double)atof(k);
            k = strtok(NULL, ",");
            lon = (double)atof(k);
            k = strtok(NULL, ",");
            el = (double)atof(k);
            k = strtok(NULL, ",");
            strcpy(file, k);
            k = strtok(NULL, ",");
            strcpy(date, k);
            void *buf = malloc(1);
            int len = vlbi_b64readfile(file, buf);
            dsp_location location;
            location.geographic.lat = lat;
            location.geographic.lon = lon;
            location.geographic.el = el;
            if(len > 0 && geo > 0) {
                AddNode(name, &location, buf, len, vlbi_time_string_to_utc(date), geo == 1);
            }
        }
    }
    else if(!strcmp(cmd, "del")) {
        if(!strcmp(arg, "node")) {
            DelNode(value);
        }
        else if(!strcmp(arg, "context")) {
            contexts->RemoveKey(value);
        }
    }
}

extern VLBI::Client *client;

static void sighandler(int signum)
{
    signal(signum, SIG_IGN);
    client->~Client();
    signal(signum, sighandler);
    exit(0);
}

int main(int argc, char** argv)
{
    char cmd[32], arg[32], value[4032], opt;
    FILE *input = stdin;
    while ((opt = getopt(argc, argv, "t:f:")) != -1) {
        switch (opt) {
        case 't':
            vlbi_max_threads((int)atof(optarg));
            break;
        case 'f':
            input = fopen (optarg, "rb+");
            break;
        default:
            fprintf(stderr, "Usage: %s [-t max_threads] [-f obs_file]\n", argv[0]);
            exit(EXIT_FAILURE);
        }
    }
    signal(SIGINT, sighandler);
    signal(SIGKILL, sighandler);
    signal(SIGILL, sighandler);
    signal(SIGSTOP, sighandler);
    signal(SIGQUIT, sighandler);
    while (is_running) {
        if(3 != fscanf(input, "%s %s %s", cmd, arg, value)) { if (!strcmp(cmd, "quit")) is_running=0; continue; }
	client->Parse(cmd, arg, value);
    }
    return EXIT_SUCCESS;
}
