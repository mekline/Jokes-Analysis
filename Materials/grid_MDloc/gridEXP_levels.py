import os, sys
import random, csv

from pygame.locals import *
from optparse import OptionParser
from VisionEgg import *
start_default_logging(); watch_exceptions()

from VisionEgg.Core import *
from VisionEgg.FlowControl import *
from VisionEgg.Textures import *
from VisionEgg.MoreStimuli import *
from VisionEgg.Text import *


##   grid numbered as:
##   ---------------------
##   | 1  | 2  | 3  | 4  |
##   ---------------------
##   | 5  | 6  | 7  | 8  |
##   ---------------------
##   | 9  | 10 | 11 | 12 |
##   ---------------------


###############

class Experiment:

    def __init__(self,n,first): #setup
        self.subj,self.run = self.parse()
        self.trials = n #number of trials
        self.first=first #starting level
        self.time = self.getTime() #trial durations
        self.ev = self.getEvOpts() #key events
        self.mid, self.fix, self.view, self.p = self.setup()
        self.wr = self.getDataWriter()
    
    def parse(self): #parse commandline opts
        parser = OptionParser()
        parser.add_option('-s','--subj',dest='subj')
        parser.add_option('-r','--run',dest='run')
        
        (opts,arg) = parser.parse_args()
        
        if opts.subj==None or opts.run==None:
            print 'ERROR:\n-s    subj (any)\n-r    run number (int)'
            sys.exit()
        else:
            return opts.subj,opts.run
    
    def getEvOpts(self): #keydown events
        KEY = pygame.locals.KEYDOWN
        return {'tr':(KEY,self.trigger), 'fin':(KEY,self.finish), 're':(KEY,self.response)}

    def getTime(self): #trial durations
        initialFix = 1.000
        flashGrid = 1.000
        twoGrid = 3.000
        return initialFix,flashGrid,twoGrid

    def setup(self): #screen, VisionEgg
        screen = Screen(bgcolor = (1,1,1), size=(1024,640),fullscreen=True)
        mid = (screen.size[0]/2.,screen.size[1]/2.)
        start = self.text('Wait for trigger',mid)

        fix = FixationCross(position = mid, size = (50,50))

        view = Viewport(screen = screen, stimuli = [start])
        p = Presentation(viewports = [view],handle_event_callbacks = [self.ev['tr']],go_duration = ('forever',))
        return mid, fix, view, p

    def getDataWriter(self): #return data file writer
        f = 'data/'+self.subj+'_run'+self.run+'_data'
        x = 1
        while os.path.isfile(f+'.csv'):
            x+=1
            f = 'data/'+self.subj+'_run'+self.run+'-x'+str(x)+'_data'
        data = open(f+'.csv','wb')
        wr = csv.writer(data,quoting=csv.QUOTE_MINIMAL)
        wr.writerow(['subj','run','trial','trialonset','choiceonset','version','leftgrid','rightgrid','correctanswer','response','accuracy','rt'])
        return wr

    def text(self,tx,pos): #return viewport text object
        return Text(anchor = 'center',
                position = pos,
                text = tx,
                font_size = 70,
                color = (0,0,0))

    def makeTrial(self,version): #choose blue trial blocks (good)
        pairs = [[1,2],[1,5],[2,3],[2,6],[3,4],
                 [3,7],[4,8],[5,6],[5,9],[6,7],
                 [6,10],[7,8],[7,11],[8,12],
                 [9,10],[10,11],[11,12],[1,9],[4,12]]
        squares = []
        i = 0
        while i<version:
            random.shuffle(pairs)
            x,y = pairs[-1]
            if x not in squares and y not in squares:
                squares+=pairs.pop()
                i+=1
        random.shuffle(squares)
        return squares

    def makeBad(self,squares): #generate wrong choice from good blocks
        s = [sq for sq in squares]
        random.shuffle(s)
        if len(s)==2: x = 1
        else: x = random.randint(1,2)
        return s[x:]+self.find_blocks(s,x)

    def find_blocks(self,s,x): #find x unused blocks
        good = False
        while not good:
            good = True
            new = random.sample(range(1,13),x)
            for i in new:
                if i in s:
                    good = False
        return new

    def drawTrial(self,squares,shift=None): #make 4x3 viewport object grid
        black = (0,0,0)
        white = (1,1,1)
        blue = (0,0,1)
        x,y = self.mid
        u = 0.2*x #unit square
        b = 0.05*u #border width
        if shift!=None:
            x=x*shift
        grid = [self.target(black,(x,y),(u*4+b/2,u*3+b/2))]
        centers = [(x+i,y+j) for j in [u,0,-u] for i in [-1.5*u,-0.5*u,0.5*u,1.5*u]]
        for i in range(len(centers)):
            if i+1 in squares: clr = blue
            else: clr = white
            grid.append(self.target(clr,centers[i],(u-b,u-b)))
        return grid
            
    def target(self,clr,pos,siz): #draw viewport rectangle object
        return Target2D(color = clr,
                        anchor = 'center',
                        position = pos,
                        size = siz)

    def drawSequence(self,squares): #split good blocks into pairs sequence
        obj = []
        n = []
        for i in range(len(squares)/2):
            obj.append(self.drawTrial(squares[i*2:(i+1)*2]))
            n.append(squares[i*2:(i+1)*2])
        return obj,n
    
    def drawChoice(self,good,bad): #assign placement of good/bad grids for choice
        d = {'l':[0.5,1.5], 'r':[1.5,0.5]}
        side = random.sample(['l','r'],1)[0]
        return [self.drawTrial(good,d[side][0])+\
                self.drawTrial(bad,d[side][1]),side]

    def getV(self): #calculate subject v
        rec = {1:[],2:[],3:[],4:[]}
        for v,a in self.record:
            rec[v].append(a)
        success={}
        for v in rec:
            if len(rec[v])==0:
                success[v]=0
            else:
                success[v]=sum(rec[v])/float(len(rec[v]))
        for i in [4,3,2,1]:
            if success[i]>=0.65:
                return i
        return 0

    def finish(self,event): #quit any time
        if event.key==pygame.locals.K_ESCAPE:
            if self.i==self.trials: #all trial complete, get v
                v = self.getV()
                print 'determined v: ',v
            sys.exit()

    def trigger(self,event): #trigger main expt loop
        if event.unicode=='+':
            self.p.parameters.handle_event_callbacks = [self.ev['fin']]
            self.p.parameters.go_duration = ('forever',)
            self.current = self.generateNext(self.first,-1,0)
            self.p.add_controller(self.view, 'stimuli', FunctionController(during_go_func = self.switch))
            self.p.go()

    def response(self,event): #choice responses
        e = {49:'l',257:'l', 50:'r',258:'r'}
        if event.key in e:
            RT = self.p.time_sec_since_go-self.choice_onset
            response = e[event.key]
            self.p.parameters.handle_event_callbacks = [self.ev['fin']]
            self.accuracy = int(response==self.current[-1])
            self.wr.writerow([self.subj,self.run,self.i+1,self.last_start,self.choice_onset]+self.current[:3]+[self.current[-1],response,self.accuracy,RT])
    
    def generateNext(self,version,accuracy,t):
        #reset trial constants
        if accuracy==-1: #initialize i=0
            self.ideal=0
            self.i=0
            self.last_three = []
            nextversion=version
            self.record = []
        else: #i>0
            if accuracy == None: accuracy = 0
            self.i+=1
            self.ideal += self.time[0]+self.j*self.time[1]+self.time[2]
            self.record.append([version,accuracy])
        self.last_start=t
        self.new=True
        self.j=1
        self.accuracy = None
        #choose next item level
        if accuracy==0:
            nextversion=max(version-1,1)
            self.last_three=[]
        elif accuracy==1:
            self.last_three+=[1]
            if sum(self.last_three)==3:
                nextversion = min(version+1,4)
                self.last_three=[]
            else:
                nextversion=version
        #generate next item
        good = self.makeTrial(nextversion)
        bad = self.makeBad(good)
        pairs_V,pairs_n = self.drawSequence(good)
        two_grids = self.drawChoice(good,bad)
        self.last_start = t
        return [nextversion,pairs_n,sorted(bad),pairs_V]+two_grids

    def switch(self,t): #main expt loop
        while self.i<self.trials: #self.current
            if t<=(self.ideal+self.time[0]): #pre-trial fixation
                return [self.fix]
            elif self.j<=self.current[0]: #pairs
                if t<=(self.ideal+self.time[0]+self.j*self.time[1]):
                    return self.current[3][self.j-1]
                else:
                    self.j+=1
                    return self.current[3][self.j-2]
            elif t<=(self.ideal+self.time[0]+self.j*self.time[1]+self.time[2]): #choice
                if self.new:
                    self.p.parameters.handle_event_callbacks = [self.ev['fin'],self.ev['re']]
                    self.choice_onset=t
                    self.new=False
                return self.current[4]
            else: #get next
                if self.accuracy==None:
                    self.wr.writerow([self.subj,self.run,self.i+1,self.last_start,self.choice_onset]+self.current[:3]+[self.current[-1],None,0,None])
                    self.p.parameters.handle_event_callbacks = [self.ev['fin']]
                self.current = self.generateNext(self.current[0],self.accuracy,t)
                return []
        print 'total time: ',t
        #end screen
        end = self.text('Thank you!',self.mid)
        self.p.remove_controller(self.view, 'stimuli')
        return [end]


###############

run = Experiment(30,2)
run.p.go()


