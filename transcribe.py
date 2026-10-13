#!/usr/bin/env python3
### command line interface of whisper-am : audio files (mp3, m4a) in a folder -> srt, txt, docx
### usage : python transcribe.py /content/drive/MyDrive/data

import argparse
import os
import sys
import time

DEFAULT_MODEL = 'guillaumekln/faster-whisper-large-v2' ### final choice. see data/memo.txt


def parseArgs () :
    parser = argparse.ArgumentParser (description='Transcribe audio files (mp3, m4a) in a folder into srt, txt and docx.')
    parser.add_argument ('data_dir', nargs='?', default='/content/drive/MyDrive/data', help='folder of input audio files (default: %(default)s)')
    parser.add_argument ('-o', '--out-dir', default='', help='output folder (default: same as data_dir)')
    parser.add_argument ('-m', '--model', default=DEFAULT_MODEL, help='faster-whisper model name (default: %(default)s)')
    parser.add_argument ('-b', '--beam-size', type=int, default=5, help='beam size (default: %(default)s)')
    parser.add_argument ('-p', '--prompt', default='', help='initial prompt (default: none)')
    parser.add_argument ('--skip-existing', action='store_true', help='skip audio files which already have a docx in out_dir')
    parser.add_argument ('--allow-cpu', action='store_true', help='run on cpu if no gpu is found (very slow)')
    return parser.parse_args ()
###


def main () :
    args = parseArgs ()

    data_dir = os.path.join (args.data_dir, '') ### WhisperAM expects a trailing slash
    out_dir  = os.path.join (args.out_dir, '') if args.out_dir else data_dir

    if not os.path.isdir (data_dir) :
        sys.exit ('data_dir not found : ' + data_dir + '\n(on colab, mount google drive in the notebook first : from google.colab import drive; drive.mount("/content/drive"))')

    from whisper_am import WhisperAM

    am = WhisperAM (args.model, data_dir, out_dir, initial_prompt=args.prompt, doc_download=False,
                    beam_size=args.beam_size, FASTER=True, skip_existing=args.skip_existing)

    files = am.getFiles (data_dir)
    if not files :
        sys.exit ('no mp3/m4a files in ' + data_dir)

    device = am.checkCuda ()
    if device != 'cuda' and not args.allow_cpu :
        sys.exit ('GPU not found. change colab runtime to GPU, or use --allow-cpu')

    print ('model  :', args.model)
    print ('device :', device)
    print ('input  :', data_dir, '(%d files)' % len (files))
    print ('output :', out_dir)
    print ('Start  :', time.strftime ('%X %x %Z'))
    am.run ()
    print ('End    :', time.strftime ('%X %x %Z'))
###


if __name__ == '__main__' :
    main ()
