import os, sys
import random, csv
import string

from optparse import OptionParser

import pygame
from pygame.locals import *

from VisionEgg import *
start_default_logging(); watch_exceptions()
from VisionEgg.Core import *
from VisionEgg.FlowControl import *
from VisionEgg.Textures import *
#from VisionEgg.MoreStimuli import *
from VisionEgg.Text import *
from VisionEgg.WrappedText import *

class Experiment:

    def __init__(self):
        self.subj, self.list, self.run, self.counter = self.parse()
        self.setup()
        self.files()
        self.make_order()
        
    def parse(self):
        parser = OptionParser()
        parser.add_option('-s','--subj',dest='subj')
        parser.add_option('-l','--list',dest='list')
        parser.add_option('-r','--run',dest='run')
        parser.add_option('-c','--counter',dest='counter')
        
        (opts,arg) = parser.parse_args()
        five = [str(i) for i in range(1,6)]
        three = five[:3]
        two = five[:2]

        if opts.subj==None or opts.list not in two or \
                opts.run not in three or opts.counter not in five:
            print 'ERROR:\n-s   subj (any)\n-l   list (1,2)\n-r   run (1-3)'
            print '-c   counterbalancing/optseq (1-5)'
            sys.exit()
        
        return opts.subj,opts.list,opts.run,opts.counter



    def setup(self):
        self.fix_t = 0.250
        self.sent_t = 5.750
        

        self.black = (0,0,0)
        self.white = (1,1,1)
        self.font_s = 72
        self.screen = Screen(bgcolor = self.white, size = (1024, 640), fullscreen =True)
        self.mid_x,self.mid_y = self.screen.size[0]/2, self.screen.size[1]/2
        self.start = self.text('wait for trigger +')
        self.fix = FixationCross(position = (self.mid_x,self.mid_y), size = (50,50))
        self.view = Viewport(screen = self.screen, stimuli = [self.start])
        self.p = Presentation(viewports = [self.view],
                              handle_event_callbacks = [
                (pygame.locals.KEYDOWN,self.trigger),
                (pygame.locals.KEYDOWN,self.finish)],
                              go_duration = ('forever',))
        self.i=0
        self.new=True
        self.resp=None
        self.RT = None
        self.choice_onset=None
        
        self.question = [self.W_text('How funny was the sentence you just read?'),
                         self.text('1 = not at all funny',1),
                         self.text('2 = a little funny',2),
                         self.text('3 = quite funny',3),
                         self.text('4 = very funny',4)]
                              
    def files(self):
        
        f = 'data/'+self.subj+'_run'+self.run
        x = 1
        while os.path.isfile(f+'_data.csv'):
            x+=1
            f = 'data/'+self.subj+'_run'+self.run+'-x'+str(x)
        self.wr = csv.writer(open(f+'_data.csv','wb'),quoting=csv.QUOTE_MINIMAL)
        self.wr.writerow(['subj','run','item','list','category','sentence','joke ending','nonjoke ending','displayed','response','RT','question onset'])


        if self.run=='1':
            a = open('materials.csv','rU')
            all_stims = [i for i in csv.reader(a) if i[1]==self.list]
            a.close()
            random.shuffle(all_stims)
            m = open('data/'+self.subj+'_materials.csv','wb')
            m_wr = csv.writer(m,quoting=csv.QUOTE_MINIMAL)
            for x in range(len(all_stims)):
                m_wr.writerow([x%3+1]+all_stims[x])
            m.close()
            

    def make_order(self):
        o = open('optseq_files-8sec/times-00'+self.counter+'.par','rU')
        optseq = [string.split(line) for line in o] #time|condition|duration|??|name
        o.close()
        
        m = open('data/'+self.subj+'_materials.csv','rU')
        all_stims = [i for i in csv.reader(m) if i[0]==self.run]
        random.shuffle(all_stims)
        
        divide = {}
        divide['joke']=all_stims[:len(all_stims)/2]
        divide['nonjoke']=all_stims[len(all_stims)/2:]

        self.order = []

         
        for o in optseq:
            if o[4]=='NULL':
                self.order.append([o[0],o[2],'fix'])
            else:
                item = divide[o[4]].pop()
                self.order.append([o[0],o[2]]+item+[self.W_text(item[7])])
        

    
   
    def W_text(self,tx):
        return WrappedText(position = (0.2*self.mid_x,1.5*self.mid_y),
                           size = (1.6*self.mid_x,self.mid_y),
                           font_size = self.font_s,
                           color = self.black,
                           text = tx)
        
    def text(self,tx,p=None):
        
        if p==None: 
            a,pos = 'center',(self.mid_x,self.mid_y)
        else: 
            a,pos = 'left',(0.2*self.mid_x,(1.2-0.2*p)*self.mid_y)
        return Text(anchor =a,
                    position = pos,
                    font_size = self.font_s-10,
                    color = self.black,
                    text = tx)


    def finish(self,event):
        if event.key == pygame.locals.K_ESCAPE:
            sys.exit()


    def trigger(self,event):
        if event.unicode=='+':
            self.p.parameters.go_duration = (0,'seconds')
            self.p.parameters.handle_event_callbacks = [
                (pygame.locals.KEYDOWN, self.finish)]
            self.p.add_controller(self.view, 'stimuli', FunctionController(
                    during_go_func = self.switch))
            self.p.parameters.go_duration = ('forever',)
            self.p.go() #start trial loop

    def response(self,event):
        if event.unicode in ['1','2','3','4']:
            self.resp = event.unicode
            self.RT = self.p.time_sec_since_go-self.choice_onset
            self.p.parameters.handle_event_callbacks = [(pygame.locals.KEYDOWN,self.finish)]

    
    def switch(self,t):
        if self.i<len(self.order):
            self.current = self.order[self.i]
            if self.current[2]=='fix':
                if t<(float(self.current[0])+float(self.current[1])):
                    return [self.fix]
                else:
                    self.i+=1
                    return [self.fix]
            else:
               
                if t<(float(self.current[0])+self.fix_t):
                    return [self.fix]
                elif t<(float(self.current[0])+self.fix_t+self.sent_t):
                    return [self.current[10]]
                elif t<(float(self.current[0])+float(self.current[1])):
                    if self.new:
                        self.choice_onset=t
                        self.new=False
                        self.p.parameters.handle_event_callbacks = [(pygame.locals.KEYDOWN,self.finish),(pygame.locals.KEYDOWN,self.response)]
                    return self.question
                else:
                    self.wr.writerow([self.subj]+self.current[2:-1]+[self.resp,self.RT,self.choice_onset])
                    self.i+=1
                    self.new=True
                    self.resp =None
                    self.RT = None
                    return [self.fix]
        else:
            self.p.parameters.go_duration = (0,'seconds')
            print 'actual duration: ',t
            return [self.fix]
                    


########
def Main():
    new_run = Experiment()
   
    new_run.p.go()

Main()
