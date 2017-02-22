
import os
import sys
import string
import Image
import random
import csv
import pygame
from pygame.locals import *
from optparse import OptionParser
from statlib import stats
from VisionEgg import *
start_default_logging(); watch_exceptions()
from VisionEgg.Core import *
from VisionEgg.FlowControl import *
from VisionEgg.Textures import *
from VisionEgg.MoreStimuli import *
from VisionEgg.Text import *



#####################



##can change to fullscreen under self.screen in __init__



## grid numbered as:
##   ---------------------
##   | 1  | 2  | 3  | 4  |
##   ---------------------
##   | 5  | 6  | 7  | 8  |
##   ---------------------
##   | 9  | 10 | 11 | 12 |
##   ---------------------

class Experiment:
    
    def __init__(self):
        
        #assign parsed options
        self.options = self.parse()
        self.subjID = self.options.subjID
        self.number = self.options.number
        self.feedback = self.options.feedback
        self.version = int(self.options.version)
        self.counter = int(self.options.counter)

        #experiment constants
        self.init_fix_time = .500
        self.flash_time = 1.000
        self.choice_time = 3.000
        self.end_fix_time = 0.500
        self.feedback_time = 0.250
        self.feedback_fix_time = 0.250
        if self.version == 1: self.big_fix_time = 20.000
        else: self.big_fix_time = 16.000

        #colors
        self.black = (0.0,0.0,0.0)
        self.white = (1.0,1.0,1.0)
        self.blue = (0.0,0.0,1.0)
        
        #screen/VisionEgg setup
        self.screen = Screen(bgcolor = (1.0,1.0,1.0), fullscreen = True)
        self.midx = self.screen.size[0]/2.0
        self.midy = self.screen.size[1]/2.0
        
        self.start = Text(anchor = 'center',
                          position = (self.midx, self.midy), 
                          text = "Wait for trigger +",
                          font_size = 70,
                          color = self.black)
        self.fix = FixationCross(position = (self.midx, self.midy),
                                 size = (50,50))
        self.yes = TextureStimulus(texture=Texture('yes.png'),
                                   color = self.white,
                                   anchor='center',
                                   position=(self.midx, self.midy),
                                   size=(250,250))
        self.no = TextureStimulus(texture=Texture('no.png'),
                                  anchor='center',
                                  position=(self.midx, self.midy),
                                  size=(200,200))
        
        self.view_start = Viewport(screen=self.screen, stimuli=[self.start])
        self.view_present = Viewport(screen=self.screen)

        self.p = Presentation()

        self.order = self.make_order(self.version,self.counter)
        self.L = []
        self.R = []

        self.i = 0
        self.j = 0

        self.last_start = 0
        self.ideal = 0
        self.trial_n = 0
        self.RT = None
        self.given_response = None
        self.correct = None
        self.condition = None
        self.choice_onset = None
        self.acc = None

        #data file setup
        self.data_file = self.make_file()
        self.wr = csv.writer(self.data_file, quoting=csv.QUOTE_MINIMAL)
        self.wr.writerow(['SubjID', 'RunNumber','Feedback',
                          'Version','Counterbalance','TrialNumber', 
                          'TrialOnset','ChoiceOnset','Condition',
                          'LeftGrid','RightGrid','CorrectAnswer',
                          'Response','Accuracy','RT'])

    def parse(self): #take command line options
        parser = OptionParser()
        parser.add_option("-s", "--subjID", dest="subjID")
        parser.add_option("-n", "--number", dest="number")
        parser.add_option("-f", "--feedback", dest="feedback")
        parser.add_option("-v", "--version", dest="version")
        parser.add_option("-c", "--counterbalance", dest="counter")
        (options,arg)=parser.parse_args()
        error = "ERROR:\n-s    give SubjID (any)\n-n    give run number (any)\n-f    make feedback choice: y or n\n-v    choose version: 1 or 2 or 3 or 4\n-c    choose counterbalance: 1 or 2"
        if options.subjID == None:
            print error            
            sys.exit()
        if options.number == None:
            print error
            sys.exit()
        if options.feedback!='y' and options.feedback!='n':
            print error
            sys.exit()
        if options.version not in ['1', '2', '3', '4']:
            print error
            sys.exit()
        if options.counter not in ['1', '2']:
            print error
            sys.exit()
        return options

    def make_file(self): #create data file, prevent over-write
        f = 'data/'+self.subjID+'_'+self.number+'_data'
        x = 1
        while os.path.isfile(f+'.csv'):
            x+=1
            f = 'data/'+self.subjID+'_'+self.number+'-x'+str(x)+'_data'
        data = open(f+'.csv','wb')
        return data


    #### MAKE ORDERS ####

    def make_order(self,v,c): #return list of fix/grids to be run
        if c==1: 
            o=['F','E','H','H','E','F','H','E','E','H','F','E','H','H','E','F']
        if c==2:
            o=['F','H','E','E','H','F','E','H','H','E','F','H','E','E','H','F']
        all = []
        for i in o:
            all+=self.make_block(v,i)
        return all
    
    def make_block(self,v,d): #make block of E/H grids/trials for version
        if d == 'F': return ['fix']
        else: return [self.set_trial(v,d) for i in range(4)]
    
    def set_trial(self,v,d): #generate set of blue squares given version (1-4) and difficulty ('E' or 'H')
        grid = range(1,13)
        pairs = [[1,2],[1,5],[2,3],[2,6],[3,4],
                 [3,7],[4,8],[5,6],[5,9],[6,7],
                 [6,10],[7,8],[7,11],[8,12],
                 [9,10],[10,11],[11,12]]
        squares = []
        if d == 'E':
            for i in range(v):
                random.shuffle(grid)
                squares.append(grid.pop())
        elif d == 'H':
            i = 0
            while i<v:
                random.shuffle(pairs)
                if pairs[i][0] not in squares and pairs[i][1] not in squares:
                    squares += pairs[i]
                    i+=1
            random.shuffle(squares)
                
                
        #returns list of blue grid numbers
        return squares
   
    def make_bad(self,squares): #makes slightly wrong test grid
        s = [sq for sq in squares]
        x = random.randint(1,2)
        if len(s)<=2 or self.condition=="Easy":
            x = 1
        random.shuffle(s)
        l = s[:-x]
        i = 0
        while i<x:
            y = random.randint(1,12)
            if y not in s and y not in l:
                l.append(y)
                i+=1
        return l
    
    def choose_left(self,current): #chooses locations of good/bad grids
        m = random.randint(1,2)
        a = [i for i in current]
        bad = self.make_bad(a)
        if bad == a: 
            print "self.choose_left error!!"
        if m==1:
            self.correct = 1
            return (a, bad)
        else: 
            self.correct = 2
            return (bad, a)

            

    #### DRAW GRIDS ####
    
    def make_stims(self, n, colorL, colorR=None): 
        #make either n = 1 or n = 2 grids w/ assigned colors
        if n==1:
            return self.make_grid(self.midx, self.midy, colorL)
        elif n==2:
            return self.make_grid(0.5*self.midx, self.midy, colorL) + self.make_grid(1.5*self.midx, self.midy,colorR)
        else:
            print "ERROR"
            sys.exit()

    def make_grid(self,x,y,colors): #given colors, fill in grid
        u = .2*self.midx #unit (square)
        b = 0.05*u #border width
        bkgrd = Target2D(color = self.black,
                         anchor = 'center',
                         position = (x,y),
                         size = (u*4+b/2., u*3+b/2.))
        
        centers = [(x-1.5*u, y+u), (x-0.5*u, y+u), (x+0.5*u, y+u), 
                   (x+1.5*u, y+u), (x-1.5*u, y), (x-0.5*u, y), 
                   (x+0.5*u, y), (x+1.5*u, y), (x-1.5*u, y-u), 
                   (x-0.5*u, y-u), (x+0.5*u, y-u), (x+1.5*u, y-u)]
        all = [bkgrd]
        for i in range(len(centers)):
            all.append(Target2D(color = colors[i], anchor = 'center', 
                                position = centers[i], size = (u-b,u-b)))
        return all

    def fill_colors(self, grids): #color in (blue) squares in list grids
        colors = [self.white]*12
        for x in grids:
            colors[x-1]=self.blue
        #returns list of colors in order 1-12
        return colors




    ######### P R E S E N T A T I O N #########

    def finish(self, event): #quit anytime
        if event.key == pygame.locals.K_ESCAPE:
            self.screen.close()
            sys.exit()  
            
         
    def trigger(self, event): #start exp    
        if event.unicode == '+': self.p.parameters.go_duration = (0, 'seconds')
        
    def trigger_screen_go(self): #trigger screen presentation
        self.p.parameters.handle_event_callbacks = [(pygame.locals.KEYDOWN, self.trigger),
                                                    (pygame.locals.KEYDOWN, self.finish)]
        self.p.parameters.go_duration = ('forever',)
        self.p.parameters.viewports = [self.view_start]
        self.p.go()

    def response(self, event): #take, record responses (1=left, 2=right)
        if event.key == pygame.locals.K_KP1 or event.key == pygame.locals.K_1: #circle
            self.RT = self.p.time_sec_since_go-self.choice_onset
            self.given_response = 1
            
            self.p.parameters.handle_event_callbacks = [(pygame.locals.KEYDOWN, self.finish)]
        if event.key == pygame.locals.K_KP2 or event.key == pygame.locals.K_2: #squareright image
            self.RT = self.p.time_sec_since_go- self.choice_onset
            self.given_response = 2
            self.p.parameters.handle_event_callbacks = [(pygame.locals.KEYDOWN, self.finish)] 
        if self.given_response == self.correct: self.acc = 1
        else: self.acc = 0



            
    def switch(self,t): #display trials
        if self.i<len(self.order):
            current = self.order[self.i]
            if current=='fix':
                if t<=(self.ideal+self.big_fix_time): 
                    return [self.fix]
                else:
                    self.i += 1
                    self.last_start = t
                    self.ideal+=self.big_fix_time
                    return [self.fix]
            else:
                if t<=(self.ideal+self.init_fix_time):
                    return [self.fix]
                elif self.j<self.version:
                    if len(current)==self.version: ##easy
                        self.condition = 'Easy'
                        if t<=(self.ideal+self.init_fix_time+(self.j+1)*self.flash_time):
                            return self.make_stims(1,self.fill_colors([current[self.j-1]]))
                        else: 
                            self.j+=1
                            return self.make_stims(1,self.fill_colors([current[self.j-1]]))
                    else: ##hard
                        self.condition = 'Hard'
                        if t<=(self.ideal+self.init_fix_time+(self.j+1)*self.flash_time):
                            return self.make_stims(1,self.fill_colors(current[2*self.j:(2*self.j+2)])) 
                        else:
                            self.j+=1
                            return self.make_stims(1,self.fill_colors(current[2*(self.j-1):2*(self.j-1)+2]))
                elif self.j == self.version:
                    (self.L,self.R) = self.choose_left(current)
                    self.j+=1
                    self.choice_onset=t
                    return self.make_stims(2,self.fill_colors(self.L), self.fill_colors(self.R))
                elif t<=(self.ideal+self.init_fix_time+(self.version)*self.flash_time+self.choice_time):
                    if self.given_response==None:
                        self.p.parameters.handle_event_callbacks = [(pygame.locals.KEYDOWN, self.response),
                                                                (pygame.locals.KEYDOWN, self.finish)]
                    return self.make_stims(2,self.fill_colors(self.L), self.fill_colors(self.R))
                elif t<=(self.ideal+self.init_fix_time+(self.version)*self.flash_time+self.choice_time+self.end_fix_time):
                    self.p.parameters.handle_event_callbacks = [(pygame.locals.KEYDOWN, self.finish)]
                    if self.feedback == 'y': ##feedback
                        if t<=(self.ideal+self.init_fix_time+(self.version)*self.flash_time+self.choice_time+self.feedback_time):
                            if self.acc==1:
                                return [self.yes]
                            else: 
                                return [self.no]
                            
                    return [self.fix]
                else:
                    ##write row in data_file
                    self.trial_n +=1
                    self.wr.writerow([self.subjID,self.number,self.feedback,self.version,self.counter,self.trial_n,self.last_start,self.choice_onset,self.condition,self.L,self.R,self.correct,self.given_response,self.acc,self.RT])


                    ##reset for next trial
                    self.last_start = t
                    self.i += 1
                    self.j = 0
                    self.acc = None
                    self.given_response = None
                    self.L = []
                    self.R = []
                    self.RT = None
                    self.correct = None
                    self.condition = None
                    self.ideal += (self.init_fix_time + (self.version)*self.flash_time+self.choice_time+self.end_fix_time) 
                    return [self.fix]

        else:
            #end presentation
            self.p.parameters.go_duration=(0,'seconds')
            return []

    def run_go(self):
        self.p.parameters.handle_event_callbacks = [(pygame.locals.KEYDOWN, self.finish)]
        self.p.parameters.go_duration = ('forever',)
        
        self.p.parameters.viewports = [self.view_present]#self.view_presentation
        self.p.add_controller(self.view_present, 'stimuli', FunctionController(during_go_func=self.switch))
        self.p.go()

        


    




def Main():
    new_run = Experiment()
    new_run.trigger_screen_go()
    new_run.run_go()


Main()
  
            
